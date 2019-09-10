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
    my $org_user = $t->generate_fixtures('user_account', { name => 'user with access via organization' });
    my $both_user = $t->generate_fixtures('user_account', { name => 'user with access both ways' });

    my $org = $t->generate_fixtures('organization');
    my $global_ws = $t->load_fixture('global_workspace');
    my $child1_ws = $global_ws->create_related('workspaces', { name => 'child 1' });

    $ws_user->create_related('user_workspace_roles', { workspace_id => $global_ws->id, role => 'ro' });
    $ws_user->create_related('user_workspace_roles', { workspace_id => $child1_ws->id, role => 'rw' });
    $org_user->create_related('user_organization_roles', { organization_id => $org->id, role => 'admin' });
    $org->create_related('organization_workspace_roles', { workspace_id => $global_ws->id, role => 'rw' });
    $org->create_related('organization_workspace_roles', { workspace_id => $child1_ws->id, role => 'admin' });

    $both_user->create_related('user_workspace_roles', { workspace_id => $global_ws->id, role => 'ro' });
    $both_user->create_related('user_organization_roles', { organization_id => $org->id, role => 'admin' });

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
        [ 'GLOBAL', $ws_user,   'ro',    1 ], # direct user access on GLOBAL
        [ 'GLOBAL', $org_user,  'ro',    1 ], # via org on GLOBAL
        [ 'GLOBAL', $both_user, 'ro',    1 ],
        [ 'child1', $null_user, 'ro',    0 ],
        [ 'child1', $ws_user,   'ro',    1 ], # indirect user access via GLOBAL, and direct user access on child 1
        [ 'child1', $org_user,  'ro',    1 ],
        [ 'child1', $both_user, 'ro',    1 ],

        [ 'GLOBAL', $null_user, 'rw',    0 ],
        [ 'GLOBAL', $ws_user,   'rw',    0 ],
        [ 'GLOBAL', $org_user,  'rw',    1 ],
        [ 'GLOBAL', $both_user, 'rw',    1 ],
        [ 'child1', $null_user, 'rw',    0 ],
        [ 'child1', $ws_user,   'rw',    1 ], # direct access on child 1
        [ 'child1', $org_user,  'rw',    1 ],
        [ 'child1', $both_user, 'rw',    1 ],

        [ 'GLOBAL', $null_user, 'admin', 0 ],
        [ 'GLOBAL', $ws_user,   'admin', 0 ],
        [ 'GLOBAL', $org_user,  'admin', 0 ],
        [ 'GLOBAL', $both_user, 'admin', 0 ],
        [ 'child1', $null_user, 'admin', 0 ],
        [ 'child1', $ws_user,   'admin', 0 ],
        [ 'child1', $org_user,  'admin', 1 ], # via org on child 1
        [ 'child1', $both_user, 'admin', 1 ], # ""
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

subtest 'user_workspace_role and organization_workspace_role role_via_for_user' => sub {
    my $t = Test::Conch->new;
    my $user = $t->generate_fixtures('user_account');
    my $org1 = $t->generate_fixtures('organization');
    my $org2 = $t->generate_fixtures('organization');
    my $global_ws = $t->load_fixture('global_workspace');
    my $child_ws = $global_ws->create_related('workspaces', { name => 'child of GLOBAL' });
    my $grandchild_ws = $child_ws->create_related('workspaces', { name => 'grandchild of GLOBAL' });

    # user is a member of both organizations, at different roles (this role never matters)
    $org1->create_related('user_organization_roles', { user_id => $user->id, role => 'rw' });
    $org2->create_related('user_organization_roles', { user_id => $user->id, role => 'ro' });

    # [ data to populate, expected result (for cmp_deeply), test name ]
    my @permutations = (
        [
            {
                user_workspace_role => [ { user_id => $user->id, workspace_id => $grandchild_ws->id, role => 'admin' } ],
            },
            methods(
                user_id => $user->id,
                workspace_id => $grandchild_ws->id,
                role => 'admin',
            ),
            'direct user access to the workspace, at admin',
        ],
        [
            {
                user_workspace_role => [ { user_id => $user->id, workspace_id => $child_ws->id, role => 'admin' } ],
            },
            methods(
                user_id => $user->id,
                workspace_id => $child_ws->id,
                role => 'admin',
            ),
            'direct user access via parent workspace, at admin',
        ],
        [
            {
                user_workspace_role => [ { user_id => $user->id, workspace_id => $global_ws->id, role => 'rw' } ],
            },
            methods(
                user_id => $user->id,
                workspace_id => $global_ws->id,
                role => 'rw',
            ),
            'direct user access via grandparent workspace, no organization',
        ],
        [
            {
                organization_workspace_role => [ { organization_id => $org1->id, workspace_id => $grandchild_ws->id, role => 'admin' } ],
            },
            methods(
                organization_id => $org1->id,
                workspace_id => $grandchild_ws->id,
                role => 'admin',
            ),
            'direct organization access to the workspace, at admin',
        ],
        [
            {
                organization_workspace_role => [ { organization_id => $org2->id, workspace_id => $child_ws->id, role => 'rw' } ],
            },
            methods(
                organization_id => $org2->id,
                workspace_id => $child_ws->id,
                role => 'rw',
            ),
            'organization access via the parent workspace',
        ],
        [
            {
                user_workspace_role => [ { user_id => $user->id, workspace_id => $child_ws->id, role => 'ro' } ],
                organization_workspace_role => [ { organization_id => $org1->id, workspace_id => $global_ws->id, role => 'rw' } ],
            },
            methods(
                organization_id => $org1->id,
                workspace_id => $global_ws->id,
                role => 'rw',
            ),
            'organization access via grandparent workspace prevails over a lower role granted directly to the user on the workspace',
        ],
        [
            {
                user_workspace_role => [ { user_id => $user->id, workspace_id => $global_ws->id, role => 'rw' } ],
                organization_workspace_role => [ { organization_id => $org1->id, workspace_id => $grandchild_ws->id, role => 'ro' } ],
            },
            methods(
                user_id => $user->id,
                workspace_id => $global_ws->id,
                role => 'rw',
            ),
            'user access via GLOBAL prevails over a lower role granted to the organization right on the workspace',
        ],
        [
            {
                user_workspace_role => [ { user_id => $user->id, workspace_id => $grandchild_ws->id, role => 'rw' } ],
                organization_workspace_role => [ { organization_id => $org1->id, workspace_id => $grandchild_ws->id, role => 'rw' } ],
            },
            methods(
                user_id => $user->id,
                workspace_id => $grandchild_ws->id,
                role => 'rw',
            ),
            'tied roles: user access to the workspace prevails over organization access to the workspace',
        ],
        [
            {
                user_workspace_role => [ { user_id => $user->id, workspace_id => $grandchild_ws->id, role => 'rw' } ],
                organization_workspace_role => [ { organization_id => $org1->id, workspace_id => $child_ws->id, role => 'rw' } ],
            },
            methods(
                user_id => $user->id,
                workspace_id => $grandchild_ws->id,
                role => 'rw',
            ),
            'tied roles: user access to the workspace prevails over organization access to the parent workspace',
        ],
        [
            {
                user_workspace_role => [ { user_id => $user->id, workspace_id => $child_ws->id, role => 'rw' } ],
                organization_workspace_role => [ { organization_id => $org1->id, workspace_id => $grandchild_ws->id, role => 'rw' } ],
            },
            methods(
                organization_id => $org1->id,
                workspace_id => $grandchild_ws->id,
                role => 'rw',
            ),
            'tied roles: organization access directly to the workspace prevails over user access to the parent workspace',
        ],
    );

    foreach my $test_data (@permutations) {
        $t->app->schema->txn_begin;

        $t->app->schema->resultset($_)->populate($test_data->[0]{$_})
            foreach keys $test_data->[0]->%*;

        cmp_deeply(
            $t->app->db_workspaces->role_via_for_user($grandchild_ws->id, $user->id),
            $test_data->[1],
            $test_data->[2],
        );

        $t->app->schema->txn_rollback;
    }
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
