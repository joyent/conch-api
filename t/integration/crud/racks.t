use Mojo::Base -strict;
use Test::More;
use Test::Warnings;
use Test::Deep;
use Data::UUID;
use Test::Conch;

my $t = Test::Conch->new;
$t->load_fixture('conch_user_global_workspace');
$t->load_fixture_set('workspace_room_rack_layout', 0);

my $uuid = Data::UUID->new;

$t->authenticate;

my $fake_id = $uuid->create_str();

my $rack = $t->load_fixture('datacenter_rack_0a');

$t->get_ok('/rack')
    ->status_is(200)
    ->json_schema_is('Racks')
    ->json_cmp_deeply([ superhashof({ name => 'rack 0a' }) ]);

$t->get_ok('/rack/'.$rack->id)
    ->status_is(200)
    ->json_schema_is('Rack')
    ->json_cmp_deeply(superhashof({ name => 'rack 0a' }));

$t->post_ok('/rack', json => { wat => 'wat' })
    ->status_is(400)
    ->json_schema_is('Error');

$t->post_ok('/rack', json => { name => 'r4ck', datacenter_room_id => $fake_id })
    ->status_is(400)
    ->json_schema_is('Error');

$t->post_ok('/rack', json => { name => 'r4ck', role => $fake_id })
    ->status_is(400)
    ->json_schema_is('Error');

$t->post_ok('/rack', json => {
        name => 'r4ck',
        datacenter_room_id => $fake_id,
        role => $rack->datacenter_rack_role_id,
    })
    ->status_is(400)
    ->json_schema_is('Error')
    ->json_is({ error => 'Room does not exist' });

$t->post_ok('/rack', json => {
        name => 'r4ck',
        datacenter_room_id => $rack->datacenter_room_id,
        role => $fake_id,
    })
    ->status_is(400)
    ->json_schema_is('Error')
    ->json_is({ error => 'Rack role does not exist' });

$t->post_ok('/rack', json => {
        name => 'r4ck',
        datacenter_room_id => $rack->datacenter_room_id,
        role => $rack->datacenter_rack_role_id,
    })
    ->status_is(303);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('Rack')
    ->json_cmp_deeply(superhashof({ name => 'r4ck' }));
my $new_rack_id = $t->tx->res->json->{id};

my $small_rack_role = $t->app->db_datacenter_rack_roles->create({ name => '10U', rack_size => 10 });

$t->post_ok('/rack/'.$rack->id, json => { role => $small_rack_role->id })
    ->status_is(400)
    ->json_schema_is('Error')
    ->json_is({ error => 'cannot resize rack: found an assigned rack layout that extends beyond the new rack_size' });

$t->post_ok("/rack/$new_rack_id", json => {
        name => 'rack',
        serial_number => 'abc',
        asset_tag => 'deadbeef',
    })
    ->status_is(303);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('Rack')
    ->json_cmp_deeply(superhashof({ name => 'rack', serial_number => 'abc', asset_tag => 'deadbeef' }));

$t->get_ok("/rack/$new_rack_id/assignment")
    ->status_is(200)
    ->json_schema_is('RackAssignments')
    ->json_is([]);

$t->delete_ok('/rack/'.$rack->id)
    ->status_is(400)
    ->json_schema_is('Error')
    ->json_is({ error => 'cannot delete a datacenter_rack when a datacenter_rack_layout is referencing it' });

$t->delete_ok("/rack/$new_rack_id")
    ->status_is(204);

$t->get_ok("/rack/$new_rack_id")
    ->status_is(404);

my $hardware_product_compute = $t->load_fixture('hardware_product_compute');
my $hardware_product_storage = $t->load_fixture('hardware_product_storage');


$t->get_ok('/rack/'.$rack->id.'/assignment')
    ->status_is(200)
    ->json_schema_is('RackAssignments')
    ->json_is([
        {
            rack_unit_start => 1,
            rack_unit_size => 2,
            device_id => undef,
            device_asset_tag => undef,
            hardware_product => $hardware_product_compute->name,
        },
        {
            rack_unit_start => 3,
            rack_unit_size => 4,
            device_id => undef,
            device_asset_tag => undef,
            hardware_product => $hardware_product_storage->name,
        },
        {
            rack_unit_start => 11,
            rack_unit_size => 4,
            device_id => undef,
            device_asset_tag => undef,
            hardware_product => $hardware_product_storage->name,
        },
    ]);
my $assignments = $t->tx->res->json;

$t->post_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_id => 'FOO',
            rack_unit_start => 2,
        },
    ])
    ->status_is(400)
    ->json_is({ error => 'missing layout for rack_unit_start 2' });

my ($device) = $t->generate_fixtures(device => { hardware_product_id => $hardware_product_storage->id });

$t->post_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_id => 'FOO', # new device
            device_asset_tag => 'ohhai',
            rack_unit_start => 1,
        },
        {
            device_id => $device->id, # existing device
            device_asset_tag => 'hello',
            rack_unit_start => 3,
        },
    ])
    ->status_is(303);

$assignments->[0]->@{qw(device_id device_asset_tag)} = ('FOO','ohhai');
$assignments->[1]->@{qw(device_id device_asset_tag)} = ($device->id,'hello');

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('RackAssignments')
    ->json_is($assignments);

$t->post_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_id => 'FOO',
            rack_unit_start => 11,
        },
    ])
    ->status_is(400)
    ->json_is({ error => 'device FOO already has an assigned location' });

$t->delete_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_id => 'FOO',
            rack_unit_start => 2,   # this rack_unit_start doesn't exist
        },
    ])
    ->status_is(404);

$t->delete_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_id => 'FOO',
            rack_unit_start => 11,   # this slot isn't occupied
        },
    ])
    ->status_is(404);

$t->delete_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_id => 'FOO',
            rack_unit_start => 3,   # wrong slot for this device
        },
    ])
    ->status_is(404);

$t->delete_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_id => 'FOO',
            rack_unit_start => 1,
        },
    ])
    ->status_is(204);

$assignments->[0]->@{qw(device_id device_asset_tag)} = ();

$t->get_ok('/rack/'.$rack->id.'/assignment')
    ->status_is(200)
    ->json_schema_is('RackAssignments')
    ->json_is($assignments);

done_testing();
# vim: set ts=4 sts=4 sw=4 et :
