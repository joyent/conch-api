use v5.26;
use strict;
use warnings;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;
use Conch::UUID 'create_uuid_str';

my $t = Test::Conch->new;
my $super_user = $t->load_fixture('super_user');
my $null_user = $t->generate_fixtures('user_account');
my $global_ws_id = $t->load_fixture('admin_user_global_workspace')->workspace_id;

$t->authenticate(email => $null_user->email);

my $t_super = Test::Conch->new(pg => $t->pg);
$t_super->authenticate(email => $super_user->email);

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
    ->location_like(qr!^/relay/${\Conch::UUID::UUID_FORMAT}$!)
foreach (0..1);

my $relay0 = $t->app->db_relays->find({ serial_number => 'relay0' });
my $relay1 = $t->app->db_relays->find({ serial_number => 'relay1' });

cmp_deeply(
    $relay0,
    methods(
        serial_number => 'relay0',
        user_id => $null_user->id,
        last_seen => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
    ),
    'relay registration updates fields',
);

my $rs = $t->app->db_relays->search({ serial_number => 'relay0' })->rows(1);

my ($relay_data) = $rs->hri->all;

$t->post_ok('/relay/relay0/register', json => { serial => 'relay0' })
    ->status_is(204)
    ->location_is('/relay/'.$relay0->id);

my ($new_relay_data) = $rs->hri->all;

isnt($new_relay_data->{last_seen}, $relay_data->{last_seen}, 'relay.last_seen has been updated');
is($new_relay_data->{updated}, $relay_data->{updated}, 'relay update timestamp did not change');

$relay0->last_seen(Conch::Time->from_string($new_relay_data->{last_seen}, lenient => 1));

$t->get_ok('/relay/'.create_uuid_str())
    ->status_is(404)
    ->log_debug_like(qr/^Could not find relay ${\Conch::UUID::UUID_FORMAT}$/);

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
        last_seen => $relay0->last_seen,
        user_id => $null_user->id,
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
        last_seen => $relay0->last_seen,
        user_id => $null_user->id,
    });

$t->get_ok('/relay')
    ->status_is(403)
    ->log_debug_is('User must be system admin');

$t_super->get_ok('/relay')
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
            last_seen => str(($relay0, $relay1)[$_]->last_seen),
            user_id => $null_user->id,
        }, (0..1)
    ]);

{
    my $other_user = $t->generate_fixtures('user_account');
    my $t2 = Test::Conch->new(pg => $t->pg);
    $t2->authenticate(email => $other_user->email);

    $t2->get_ok('/relay')
        ->status_is(403)
        ->log_debug_is('User must be system admin');

    $t2->get_ok('/relay/relay0')
        ->status_is(403)
        ->log_debug_is('User cannot access unregistered relay relay0');

    $t2->post_ok('/relay/relay0/register', json => { serial => 'relay0' })
        ->status_is(204)
        ->location_is('/relay/'.$relay0->id);

    $t2->get_ok('/relay/relay0')
        ->status_is(200)
        ->json_schema_is('Relay')
        ->json_cmp_deeply({
            (map +($_ => str($relay0->$_)), qw(id serial_number name version ipaddr ssh_port created)),
            last_seen => ignore,
            updated => ignore,
            user_id => $other_user->id,
        });
    isnt($t2->tx->res->json->{updated}, $relay0->updated, 'updated timestamp has changed');
}

$relay0->update({
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

$t_super->get_ok('/relay')
    ->status_is(200)
    ->json_schema_is('Relays')
    ->json_cmp_deeply('', superbagof(superhashof({
            serial_number => 'relay0',
            version => 'v2.0',
        })), 'version was updated');

my $y2000 = Conch::Time->new(year => 2000);
cmp_ok($relay0->last_seen, '>', $y2000, 'relay last_seen was updated');

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

subtest delete => sub {
    $t->delete_ok('/relay/'.$relay0->id)
        ->status_is(403)
        ->log_debug_is('User must be system admin');

    $t_super->delete_ok('/relay/'.$relay0->id)
        ->status_is(204)
        ->log_debug_is('Deactivated relay '.$relay0->id.', removing 2 associated device connections');

    $t_super->get_ok('/relay/'.$relay0->id)
        ->status_is(410);

    $t_super->delete_ok('/relay/'.$relay0->id)
        ->status_is(410);
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
