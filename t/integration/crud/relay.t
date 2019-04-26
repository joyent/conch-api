use v5.26;
use strict;
use warnings;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;

my $t = Test::Conch->new;
my $global_ws_id = $t->load_fixture('conch_user_global_workspace')->workspace_id;

$t->authenticate;

$t->get_ok('/workspace/'.$global_ws_id.'/relay')
    ->status_is(200)
    ->json_schema_is('WorkspaceRelays')
    ->json_is([]);

# two workspaces under GLOBAL, each with a room,rack and layout.
$t->load_fixture_set('workspace_room_rack_layout', $_) for 0..1;

my $workspaces_rs = $t->app->db_workspaces->search({ 'workspace.name' => 'GLOBAL' })
    ->related_resultset('workspaces')->order_by('workspaces.name');

my @workspace_ids = $workspaces_rs->get_column('id')->all;

# get all rack layouts in both workspaces into a two-dimensional array;
# create and assign one device to each layout.
my $device_num = 0;
my @rack_layouts = map {
    my @_layouts = $workspaces_rs->search({ 'workspaces.id' => $_ })
        ->related_resultset('workspace_racks')
        ->related_resultset('rack')
        ->related_resultset('rack_layouts')
        ->order_by('rack_unit_start')->hri->all;
    $t->app->db_device_locations->assign_device_location(
        'DEVICE'.$device_num++, $_->{rack_id}, $_->{rack_unit_start}
    ) foreach @_layouts;
    \@_layouts
} @workspace_ids;

# create two relays
my @relays = $t->app->db_relays->populate([
    map +{
        id => "relay$_",
        alias => "relay_number_$_",
        version => "v1.$_",
        ipaddr => "192.168.${_}.2",
        ssh_port => 123,
        created => '2000-01-01',
        updated => '2018-02-01',
    }, (0..1)
]);

# now register the relays on various devices in both workspace racks...

$relays[0]->create_related('device_relay_connections', $_) foreach (
    {
        device_id => 'DEVICE0',         # workspace 0, layout 0
        first_seen => '2001-01-01',
        last_seen => '2018-01-01',
    },
    {
        device_id => 'DEVICE5',         # workspace 1, layout 2
        first_seen => '2001-01-01',
        last_seen => '2018-01-02',      # <-- latest known location for relay0
    },
);

$relays[1]->create_related('device_relay_connections', $_) foreach (
    {
        device_id => 'DEVICE2',         # workspace 0, layout 2
        first_seen => '2001-01-01',
        last_seen => '2018-01-02',
    },
    {
        device_id => 'DEVICE4',         # workspace 1, layout 1
        first_seen => '2001-01-01',
        last_seen => '2018-01-03',
    },
    {
        device_id => 'DEVICE0',         # workspace 0, layout 0
        first_seen => '2001-01-01',
        last_seen => '2018-01-04',      # <-- latest known location for relay1
    },
);

subtest list => sub {
    # the global workspace can see all relays, by virtue of all rooms being in the global workspace.
    $t->get_ok("/workspace/$global_ws_id/relay")
        ->status_is(200)
        ->json_schema_is('WorkspaceRelays')
        ->json_is([
            {
                id      => 'relay0',
                alias   => 'relay_number_0',
                version => 'v1.0',
                ipaddr  => '192.168.0.2',
                ssh_port => 123,
                created => '2000-01-01T00:00:00.000Z',
                updated => '2018-02-01T00:00:00.000Z',
                location => {
                    $rack_layouts[1][2]->%{qw(rack_id rack_unit_start)},
                    rack_name => 'rack 1a',
                    role_name => 'rack_role 42U',
                    az => 'room-1a',
                },
                last_seen => '2018-01-02T00:00:00.000Z',
                num_devices => 2,
            },
            {
                id => 'relay1',
                alias   => 'relay_number_1',
                version => 'v1.1',
                ipaddr  => '192.168.1.2',
                ssh_port => 123,
                created => '2000-01-01T00:00:00.000Z',
                updated => '2018-02-01T00:00:00.000Z',
                location => {
                    $rack_layouts[0][0]->%{qw(rack_id rack_unit_start)},
                    rack_name => 'rack 0a',
                    role_name => 'rack_role 42U',
                    az => 'room-0a',
                },
                last_seen => '2018-01-04T00:00:00.000Z',
                num_devices => 3,
            },
        ]);

    my $all_relays = $t->tx->res->json;

    $t->get_ok("/workspace/$workspace_ids[0]/relay")
        ->status_is(200)
        ->json_schema_is('WorkspaceRelays')
        ->json_is('', [ $all_relays->[1] ], 'this workspace can only see relay1');

    $t->get_ok("/workspace/$workspace_ids[1]/relay")
        ->status_is(200)
        ->json_schema_is('WorkspaceRelays')
        ->json_is('', [ $all_relays->[0] ], 'this workspace can only see relay0');


    # calculate how many minutes it's been since that last relay updated
    my $elapsed_minutes =
        int((Conch::Time->now->epoch - Conch::Time->new('2018-01-04T00:00:00.000Z')->epoch) / 60) + 2;

    $t->get_ok("/workspace/$global_ws_id/relay?active_within=$elapsed_minutes")
        ->status_is(200)
        ->json_schema_is('WorkspaceRelays')
        ->json_is('', [ $all_relays->[1] ],
            'X minutes after last update, active_within=X+2 only sees one relay');
};

subtest get_relay_devices => sub {
    $t->get_ok("/workspace/$global_ws_id/relay/relay0/device")
        ->status_is(200)
        ->json_schema_is('Devices')
        ->json_cmp_deeply('', [
            superhashof({ id => 'DEVICE0' }),
            superhashof({ id => 'DEVICE5' }),
        ]);

    $t->get_ok("/workspace/$global_ws_id/relay/relay1/device")
        ->status_is(200)
        ->json_schema_is('Devices')
        ->json_cmp_deeply([
            superhashof({ id => 'DEVICE0' }),
            superhashof({ id => 'DEVICE2' }),
            superhashof({ id => 'DEVICE4' }),
        ]);

    $t->get_ok("/workspace/$workspace_ids[0]/relay/relay0/device")
        ->status_is(200)
        ->json_schema_is('Devices')
        ->json_cmp_deeply([
            superhashof({ id => 'DEVICE0' }),
        ]);

    $t->get_ok("/workspace/$workspace_ids[0]/relay/relay1/device")
        ->status_is(200)
        ->json_schema_is('Devices')
        ->json_cmp_deeply([
            superhashof({ id => 'DEVICE0' }),
            superhashof({ id => 'DEVICE2' }),
        ]);

    $t->get_ok("/workspace/$workspace_ids[1]/relay/relay0/device")
        ->status_is(200)
        ->json_schema_is('Devices')
        ->json_cmp_deeply([
            superhashof({ id => 'DEVICE5' }),
        ]);

    $t->get_ok("/workspace/$workspace_ids[1]/relay/relay1/device")
        ->status_is(200)
        ->json_schema_is('Devices')
        ->json_cmp_deeply([
            superhashof({ id => 'DEVICE4' }),
        ]);
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
