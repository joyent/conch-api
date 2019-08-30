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
    my $ws_user = $t->generate_fixtures('user_account', { name => 'user with direct workspace access' });

    my $global_ws = $t->load_fixture('global_workspace');
    my $child1_ws = $global_ws->create_related('workspaces', { name => 'child 1' });

    $ws_user->create_related('user_workspace_roles', { workspace_id => $global_ws->id, role => 'ro' });
    $ws_user->create_related('user_workspace_roles', { workspace_id => $child1_ws->id, role => 'rw' });

    my @racks = map { first { $_->isa('Conch::DB::Result::Rack') } $t->generate_fixtures('rack') } 0..1;
    $racks[1]->create_related('workspace_racks', { workspace_id => $child1_ws->id });

    my $hwp = first { $_->isa('Conch::DB::Result::HardwareProduct') } $t->generate_fixtures('hardware_product');
    my @layouts = map $_->create_related('rack_layouts', { rack_unit_start => 1, hardware_product_id => $hwp->id }), @racks;
    my @devices = map { first { $_->isa('Conch::DB::Result::Device') } $t->generate_fixtures('device') } 0..1;
    $layouts[$_]->create_related('device_location', { device_id => $devices[$_]->id }) foreach 0..1;

    my %objects = (
        GLOBAL => { workspace => $global_ws, rack => $racks[0], device => $devices[0] },
        child1 => { workspace => $child1_ws, rack => $racks[1], device => $devices[1] },
    );

    # [ set name, user, role, expected value ]
    my @tests = (
        [ 'GLOBAL', $null_user, 'ro',    0 ],
        [ 'GLOBAL', $ws_user,   'ro',    1 ], # direct access on GLOBAL
        [ 'child1', $null_user, 'ro',    0 ],
        [ 'child1', $ws_user,   'ro',    1 ], # indirect access via GLOBAL, and direct on child 1

        [ 'GLOBAL', $null_user, 'rw',    0 ],
        [ 'GLOBAL', $ws_user,   'rw',    0 ],
        [ 'child1', $null_user, 'rw',    0 ],
        [ 'child1', $ws_user,   'rw',    1 ], # direct access on child 1

        [ 'GLOBAL', $null_user, 'admin', 0 ],
        [ 'GLOBAL', $ws_user,   'admin', 0 ],
        [ 'child1', $null_user, 'admin', 0 ],
        [ 'child1', $ws_user,   'admin', 0 ],
    );

    # remember, you can set DBIC_TRACE=1 while you run the tests to see
    # all the crazy joins that are involved in making all this work...
    foreach my $test (@tests) {
        my ($set_name, $user, $role, $expected) = $test->@*;

        my ($workspace, $rack, $device) = $objects{$set_name}->@{qw(workspace rack device)};

        my $ws_result = $workspace->self_rs->user_has_role($user->id, $role);
        ok(
            ($ws_result xor !$expected),
            $user->name.' can'.($expected ? '' : 'not')
                .' access the \''.$workspace->name.'\' workspace at '.$role);

        my $rack_result = $rack->self_rs->user_has_role($user->id, $role);
        ok(
            ($rack_result xor !$expected),
            $user->name.' can'.($expected ? '' : 'not').' access the rack at '.$role);

        my $device_result = $device->self_rs->user_has_role($user->id, $role);
        ok(
            ($device_result xor !$expected),
            $user->name.' can'.($expected ? '' : 'not').' access the device at '.$role);

        is(
            $device->self_rs->with_user_role($user->id, $role)->count,
            $expected,
            $user->name.' can'.($expected ? '' : 'not').' access the device at '.$role.' (filtered through a resultset)');
    }
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
