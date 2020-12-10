use v5.26;
use Mojo::Base -strict, -signatures;
use Test::More;
use Test::Conch;
use Test::Warnings ':all';
use Test::Deep;
use List::Util 'first';

subtest 'user-role access' => sub {
    my $t = Test::Conch->new;

    my $null_user = $t->generate_fixtures('user_account', { name => 'user with no access' });
    my $build_user = $t->generate_fixtures('user_account', { name => 'user with direct build access' });
    my $org_user = $t->generate_fixtures('user_account', { name => 'user with access via organization' });
    my $both_user = $t->generate_fixtures('user_account', { name => 'user with access both ways' });

    my $org = $t->generate_fixtures('organization');
    my $build = $t->generate_fixtures('build');

    $build_user->create_related('user_build_roles', { build_id => $build->id, role => 'ro' });
    $org_user->create_related('user_organization_roles', { organization_id => $org->id, role => 'admin' });
    $org->create_related('organization_build_roles', { build_id => $build->id, role => 'rw' });

    $both_user->create_related('user_build_roles', { build_id => $build->id, role => 'ro' });
    $both_user->create_related('user_organization_roles', { organization_id => $org->id, role => 'admin' });

    my $rack = first { $_->isa('Conch::DB::Result::Rack') } $t->generate_fixtures('rack');
    my $hwp = first { $_->isa('Conch::DB::Result::HardwareProduct') } $t->generate_fixtures('hardware_product');
    my $layout = $rack->create_related('rack_layouts', { rack_unit_start => 1, hardware_product_id => $hwp->id });
    my @devices = map { first { $_->isa('Conch::DB::Result::Device') } $t->generate_fixtures('device') } 0..1;

    # device 0 is in the build directly.
    $devices[0]->update({ build_id => $build->id });

    # device 1 is in a rack, which is in the build.
    $layout->create_related('device_location', { device_id => $devices[1]->id });
    $rack->update({ build_id => $build->id });

    # [ user, role, expected value ]
    my @tests = (
        [ $null_user, 'none',  1 ],
        [ $build_user,'none',  1 ],
        [ $org_user,  'none',  1 ],
        [ $both_user, 'none',  1 ],

        [ $null_user, 'ro',    0 ],
        [ $build_user,'ro',    1 ], # direct user access on build
        [ $org_user,  'ro',    1 ], # via org on build
        [ $both_user, 'ro',    1 ],

        [ $null_user, 'rw',    0 ],
        [ $build_user,'rw',    0 ],
        [ $org_user,  'rw',    1 ],
        [ $both_user, 'rw',    1 ],

        [ $null_user, 'admin', 0 ],
        [ $build_user,'admin', 0 ],
        [ $org_user,  'admin', 0 ],
        [ $both_user, 'admin', 0 ],
    );

    # remember, you can set DBIC_TRACE=1 while you run the tests to see
    # all the crazy joins that are involved in making all this work...
    foreach my $test (@tests) {
        my ($user, $role, $expected) = $test->@*;

        my $build_result = $build->self_rs->user_has_role($user->id, $role);
        ok(
            ($build_result xor !$expected),
            $user->name.' can'.($expected ? '' : 'not')
                .' access the \''.$build->name.'\' build at '.$role);

        my $rack_result = $rack->self_rs->user_has_role($user->id, $role);
        ok(
            ($rack_result xor !$expected),
            $user->name.' can'.($expected ? '' : 'not').' access the rack at '.$role);

        my $device_result_0 = $devices[0]->self_rs->user_has_role($user->id, $role);
        ok(
            ($device_result_0 xor !$expected),
            $user->name.' can'.($expected ? '' : 'not').' access the device (in build directly) at '.$role);

        is(
            $devices[0]->self_rs->with_user_role($user->id, $role)->count,
            $expected,
            $user->name.' can'.($expected ? '' : 'not').' access the device (in build directly) at '.$role.' (filtered through a resultset)');


        my $device_result_1 = $devices[1]->self_rs->user_has_role($user->id, $role);
        ok(
            ($device_result_1 xor !$expected),
            $user->name.' can'.($expected ? '' : 'not').' access the device (in build via rack) at '.$role);

        is(
            $devices[1]->self_rs->with_user_role($user->id, $role)->count,
            $expected,
            $user->name.' can'.($expected ? '' : 'not').' access the device (in build via rack) at '.$role.' (filtered through a resultset)');
    }
};

subtest role_cmp => sub {
    my $obj = Conch::DB::Result::UserBuildRole->new;

    is($obj->role_cmp(undef, undef),    0, 'undef == undef');
    is($obj->role_cmp(undef, 'ro'),     -1, 'undef < ro');
    is($obj->role_cmp(undef, 'rw'),     -1, 'undef < rw');
    is($obj->role_cmp(undef, 'admin'),  -1, 'undef < admin');

    is($obj->role_cmp('ro', undef),     1, 'ro > undef');
    is($obj->role_cmp('ro', 'ro'),      0, 'ro == ro');
    is($obj->role_cmp('ro', 'rw'),      -1, 'ro < rw');
    is($obj->role_cmp('ro', 'admin'),   -1, 'ro < admin');

    is($obj->role_cmp('rw', undef),     1, 'rw > undef');
    is($obj->role_cmp('rw', 'ro'),      1, 'rw > ro');
    is($obj->role_cmp('rw', 'rw'),      0, 'rw == rw');
    is($obj->role_cmp('rw', 'admin'),   -1, 'rw < admin');

    is($obj->role_cmp('admin', undef),  1, 'admin > undef');
    is($obj->role_cmp('admin', 'ro'),   1, 'admin > ro');
    is($obj->role_cmp('admin', 'rw'),   1, 'admin > rw');
    is($obj->role_cmp('admin', 'admin'),0, 'admin == admin');

    is($obj->role_cmp(undef),    0, 'undef == undef');
    is($obj->role_cmp('ro'),     -1, 'undef < ro');
    is($obj->role_cmp('rw'),     -1, 'undef < rw');
    is($obj->role_cmp('admin'),  -1, 'undef < admin');

    $obj->set_column('role', 'ro');
    is($obj->role_cmp(undef),     1, 'ro > undef');
    is($obj->role_cmp('ro'),      0, 'ro == ro');
    is($obj->role_cmp('rw'),      -1, 'ro < rw');
    is($obj->role_cmp('admin'),   -1, 'ro < admin');

    $obj->set_column('role', 'rw');
    is($obj->role_cmp(undef),     1, 'rw > undef');
    is($obj->role_cmp('ro'),      1, 'rw > ro');
    is($obj->role_cmp('rw'),      0, 'rw == rw');
    is($obj->role_cmp('admin'),   -1, 'rw < admin');

    $obj->set_column('role', 'admin');
    is($obj->role_cmp(undef),  1, 'admin > undef');
    is($obj->role_cmp('ro'),   1, 'admin > ro');
    is($obj->role_cmp('rw'),   1, 'admin > rw');
    is($obj->role_cmp('admin'),0, 'admin == admin');
};

done_testing;
# vim: set sts=2 sw=2 et :
