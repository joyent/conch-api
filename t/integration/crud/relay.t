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
my @devices;
my @rack_layouts = map {
    my @_layouts = $workspaces_rs->search({ 'workspaces.id' => $_ })
        ->related_resultset('workspace_racks')
        ->related_resultset('rack')
        ->related_resultset('rack_layouts')
        ->order_by('rack_unit_start')->hri->all;
    push @devices, map $t->app->db_devices->create({
        serial_number => 'DEVICE'.$device_num++,
        hardware_product_id => $_->{hardware_product_id},
        health  => 'unknown',
        device_location => { $_->%{qw(rack_id rack_unit_start)} },
    }), @_layouts;
    \@_layouts
} @workspace_ids;

$t->post_ok('/relay/relay'.$_.'/register',
        json => {
            serial => 'relay'.$_,
            name => 'relay_number_'.$_,
            version => 'v1.'.$_,
            ipaddr => '192.168.'.$_.'.2',
            ssh_port => 123,
        })
    ->status_is(201)
    ->location_like(qr!^/relay/${\Conch::UUID::UUID_FORMAT}!)
foreach (0..1);

my $relay0 = $t->app->db_relays->find({ serial_number => 'relay0' });
my $relay1 = $t->app->db_relays->find({ serial_number => 'relay1' });

cmp_deeply(
    [ $relay0->user_relay_connections ],
    [
        methods(
            user_id => $t->app->db_user_accounts->search({ email => $t->CONCH_EMAIL })->get_column('id')->single,
            first_seen => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            last_seen => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        ),
    ],
    'user_relay_connection timestamps are set',
);

my $rs = $t->app->db_relays->search({ serial_number => 'relay0' })->rows(1)->prefetch('user_relay_connections');

my ($relay_data) = $rs->hri->all;

$t->post_ok('/relay/relay0/register', json => { serial => 'relay0' })
    ->status_is(204)
    ->location_is('/relay/'.$relay0->id);

my ($new_relay_data) = $rs->hri->all;

isnt(
    $new_relay_data->{user_relay_connections}[0]{last_seen},
    $relay_data->{user_relay_connections}[0]{last_seen},
    'user_relay_connection.last_seen has been updated',
);

is($new_relay_data->{updated}, $relay_data->{updated}, 'relay itself was not changed');

$t->get_ok('/relay/'.$relay0->id)
    ->status_is(200)
    ->json_schema_is('Relay')
    ->json_is({
        id => $relay0->id,
        serial_number => 'relay0',
        name => 'relay_number_0',
        version => 'v1.0',
        ipaddr => '192.168.0.2',
        ssh_port => 123,
        created => $relay0->created,
        updated => $relay0->updated,
    });

$t->get_ok('/relay/relay0')
    ->status_is(200)
    ->json_schema_is('Relay')
    ->json_is({
        id => $relay0->id,
        serial_number => 'relay0',
        name => 'relay_number_0',
        version => 'v1.0',
        ipaddr => '192.168.0.2',
        ssh_port => 123,
        created => $relay0->created,
        updated => $relay0->updated,
    });

$t->get_ok('/relay')
    ->status_is(200)
    ->json_schema_is('Relays')
    ->json_cmp_deeply([
        map +{
            id => ($relay0, $relay1)[$_]->id,
            serial_number => 'relay'.$_,
            name => 'relay_number_'.$_,
            version => 'v1.'.$_,
            ipaddr => '192.168.'.$_.'.2',
            ssh_port => 123,
            created => str(($relay0, $relay1)[$_]->created),
            updated => str(($relay0, $relay1)[$_]->updated),
        }, (0..1)
    ]);

{
    my $other_user = $t->generate_fixtures('user_account');
    my $t2 = Test::Conch->new(pg => $t->pg);
    $t2->authenticate(email => $other_user->email);

    $t2->get_ok('/relay')
        ->status_is(403);

    $t2->get_ok('/relay/relay0')
        ->status_is(403);

    $t2->post_ok('/relay/relay0/register', json => { serial => 'relay0' })
        ->status_is(204)
        ->location_is('/relay/'.$relay0->id);

    $t2->get_ok('/relay/relay0')
        ->status_is(200)
        ->json_schema_is('Relay')
        ->json_is({ map +($_ => $relay0->$_), qw(id serial_number name version ipaddr ssh_port created updated) });
}

$relay0->user_relay_connections->update({
    first_seen => '1999-01-01',
    last_seen => '1999-01-01',
});

$t->post_ok('/relay/relay0/register',
        json => {
            serial => 'relay0',
            version => 'v2.0',
        })
    ->status_is(204)
    ->location_is('/relay/'.$relay0->id);

$relay0->discard_changes;    # reload from db

$t->get_ok('/relay')
    ->status_is(200)
    ->json_schema_is('Relays')
    ->json_cmp_deeply('', superbagof(superhashof({
            serial_number => 'relay0',
            version => 'v2.0',
        })), 'version was updated');

my $y2000 = Conch::Time->new(year => 2000);
cmp_ok(($relay0->user_relay_connections)[0]->first_seen, '<', $y2000, 'first_seen was not updated');
cmp_ok(($relay0->user_relay_connections)[0]->last_seen, '>', $y2000, 'last_seen was updated');

# now register the relays on various devices in both workspace racks...

$t->app->db_device_relay_connections->create($_) foreach (
    {
        relay_id => $relay0->id,
        device_id => $devices[0]->id,   # workspace 0, layout 0
        first_seen => '2001-01-01',
        last_seen => '2018-01-01',
    },
    {
        relay_id => $relay0->id,
        device_id => $devices[5]->id,   # workspace 1, layout 2
        first_seen => '2001-01-01',
        last_seen => '2018-01-02',      # <-- latest known location for relay0
    },
);

$t->app->db_device_relay_connections->create($_) foreach (
    {
        relay_id => $relay1->id,
        device_id => $devices[2]->id,   # workspace 0, layout 2
        first_seen => '2001-01-01',
        last_seen => '2018-01-02',
    },
    {
        relay_id => $relay1->id,
        device_id => $devices[4]->id,   # workspace 1, layout 1
        first_seen => '2001-01-01',
        last_seen => '2018-01-03',
    },
    {
        relay_id => $relay1->id,
        device_id => $devices[0]->id,   # workspace 0, layout 0
        first_seen => '2001-01-01',
        last_seen => '2018-01-04',      # <-- latest known location for relay1
    },
);

subtest list => sub {
    # the global workspace can see all relays, by virtue of all rooms being in the global workspace.
    $t->get_ok("/workspace/$global_ws_id/relay")
        ->status_is(200)
        ->json_schema_is('WorkspaceRelays')
        ->json_cmp_deeply([
            {
                id => $relay0->id,
                serial_number => 'relay0',
                name => 'relay_number_0',
                version => 'v2.0',
                ipaddr  => '192.168.0.2',
                ssh_port => 123,
                created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
                updated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
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
                id => $relay1->id,
                serial_number => 'relay1',
                name => 'relay_number_1',
                version => 'v1.1',
                ipaddr  => '192.168.1.2',
                ssh_port => 123,
                created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
                updated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
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

    $t->get_ok("/workspace/$global_ws_id/relay?active_minutes=$elapsed_minutes")
        ->status_is(200)
        ->json_schema_is('WorkspaceRelays')
        ->json_is('', [ $all_relays->[1] ],
            'X minutes after last update, active_minutes=X+2 only sees one relay');
};

my $relay0_id = $relay0->id;
my $relay1_id = $relay1->id;

subtest get_relay_devices => sub {
    $t->get_ok("/workspace/$global_ws_id/relay/$relay0_id/device")
        ->status_is(200)
        ->json_schema_is('Devices')
        ->json_cmp_deeply('', [
            superhashof({ id => $devices[0]->id }),
            superhashof({ id => $devices[5]->id }),
        ]);

    $t->get_ok("/workspace/$global_ws_id/relay/$relay1_id/device")
        ->status_is(200)
        ->json_schema_is('Devices')
        ->json_cmp_deeply([
            superhashof({ id => $devices[0]->id }),
            superhashof({ id => $devices[2]->id }),
            superhashof({ id => $devices[4]->id }),
        ]);

    $t->get_ok("/workspace/$workspace_ids[0]/relay/$relay0_id/device")
        ->status_is(200)
        ->json_schema_is('Devices')
        ->json_cmp_deeply([
            superhashof({ id => $devices[0]->id }),
        ]);

    $t->get_ok("/workspace/$workspace_ids[0]/relay/$relay1_id/device")
        ->status_is(200)
        ->json_schema_is('Devices')
        ->json_cmp_deeply([
            superhashof({ id => $devices[0]->id }),
            superhashof({ id => $devices[2]->id }),
        ]);

    $t->get_ok("/workspace/$workspace_ids[1]/relay/$relay0_id/device")
        ->status_is(200)
        ->json_schema_is('Devices')
        ->json_cmp_deeply([
            superhashof({ id => $devices[5]->id }),
        ]);

    $t->get_ok("/workspace/$workspace_ids[1]/relay/$relay1_id/device")
        ->status_is(200)
        ->json_schema_is('Devices')
        ->json_cmp_deeply([
            superhashof({ id => $devices[4]->id }),
        ]);
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
