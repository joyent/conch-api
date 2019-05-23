use Mojo::Base -strict;
use Test::More;
use Test::Warnings;
use Test::Deep;
use Data::UUID;
use Test::Conch;

my $t = Test::Conch->new;
$t->load_fixture('conch_user_global_workspace');

$t->authenticate;

$t->get_ok('/rack')
    ->status_is(200)
    ->json_schema_is('Racks')
    ->json_is([]);

$t->load_fixture_set('workspace_room_rack_layout', 0);

my $uuid = Data::UUID->new;
my $fake_id = $uuid->create_str;

my $rack = $t->load_fixture('rack_0a');

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
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/', message => re(qr/properties not allowed/i) } ]);

$t->post_ok('/rack', json => { name => 'r4ck', datacenter_room_id => $fake_id })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/role', message => re(qr/missing property/i) } ]);

$t->post_ok('/rack', json => { name => 'r4ck', role => $fake_id })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/datacenter_room_id', message => re(qr/missing property/i) } ]);

$t->post_ok('/rack', json => {
        name => 'r4ck',
        datacenter_room_id => $fake_id,
        role => $rack->rack_role_id,
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
        role => $rack->rack_role_id,
    })
    ->status_is(303);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('Rack')
    ->json_cmp_deeply({
        id => re(Conch::UUID::UUID_FORMAT),
        name => 'r4ck',
        datacenter_room_id => $rack->datacenter_room_id,
        role => $rack->rack_role_id,
        serial_number => undef,
        asset_tag => undef,
        phase => 'integration',
        created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        updated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
    });
my $new_rack_id = $t->tx->res->json->{id};

my $small_rack_role = $t->app->db_rack_roles->create({ name => '10U', rack_size => 10 });

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

$t->post_ok("/rack/$new_rack_id", json => { role => $small_rack_role->id })
    ->status_is(303);

$t->post_ok("/rack/$new_rack_id", json => { role => $small_rack_role->id })
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
    ->json_is({ error => 'cannot delete a rack when a rack_layout is referencing it' });

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
    ->status_is(303)
    ->location_is('/rack/'.$rack->id.'/assignment');

$assignments->[0]->@{qw(device_id device_asset_tag)} = ('FOO','ohhai');
$assignments->[1]->@{qw(device_id device_asset_tag)} = ($device->id,'hello');

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('RackAssignments')
    ->json_is($assignments);

subtest 'rack phases' => sub {
    my $device_phase_rs = $t->app->db_devices
        ->search({ id => { -in => [ grep defined, map $_->{device_id}, $assignments->@* ] } })
        ->columns([qw(id phase)])->hri;

    cmp_deeply(
        [ $device_phase_rs->all ],
        bag(
            { id => 'FOO', phase => 'integration' },
            { id => $device->id, phase => 'integration' },
        ),
        'all assigned devices are initially in the integration phase',
    );

    $t->post_ok('/rack/'.$rack->id.'/phase?rack_only=1', json => { phase => 'production' })
        ->status_is(303)
        ->location_is('/rack/'.$rack->id);

    $t->get_ok('/rack/'.$rack->id)
        ->status_is(200)
        ->json_schema_is('Rack')
        ->json_is('/phase', 'production');

    cmp_deeply(
        [ $device_phase_rs->all ],
        bag(
            { id => 'FOO', phase => 'integration' },
            { id => $device->id, phase => 'integration' },
        ),
        'all assigned devices are still in the integration phase',
    );

    $t->post_ok('/rack/'.$rack->id.'/phase', json => { phase => 'production' })
        ->status_is(303)
        ->location_is('/rack/'.$rack->id);

    cmp_deeply(
        [ $device_phase_rs->all ],
        bag(
            { id => 'FOO', phase => 'production' },
            { id => $device->id, phase => 'production' },
        ),
        'all assigned devices are moved to the production phase',
    );
};

$t->post_ok('/rack/'.$rack->id.'/assignment', json => [
        { device_id => 'FOO', rack_unit_start => 11 },
        { device_id => 'FOO', rack_unit_start => 13 },
    ])
    ->status_is(400)
    ->json_is({ error => 'duplication of device_ids is not permitted' });

$t->post_ok('/rack/'.$rack->id.'/assignment', json => [
        { device_id => 'FOO', rack_unit_start => 11 },
        { device_id => 'BAR', rack_unit_start => 11 },
    ])
    ->status_is(400)
    ->json_is({ error => 'duplication of rack_unit_starts is not permitted' });

# move FOO from rack unit 1 to rack unit 3; pushing out the existing occupant of 3
# BAR is created and put in rack unit 11.
$t->post_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_id => 'FOO',
            rack_unit_start => 3,
        },
        {
            device_id => 'BAR',
            rack_unit_start => 11,
        },
    ])
    ->status_is(303);

$assignments->[1]->@{qw(device_id device_asset_tag)} = $assignments->[0]->@{qw(device_id device_asset_tag)};
$assignments->[0]->@{qw(device_id device_asset_tag)} = (undef, undef);
$assignments->[2]->{device_id} = 'BAR';

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('RackAssignments')
    ->json_is($assignments);

ok(!$t->app->db_device_locations->search({ device_id => $device->id })->exists, 'previous occupant is now homeless');

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
            rack_unit_start => 1,   # this slot isn't occupied
        },
    ])
    ->status_is(404);

$t->delete_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_id => 'FOO',
            rack_unit_start => 11,  # wrong slot for this device
        },
    ])
    ->status_is(404);

$t->delete_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_id => 'FOO',
            rack_unit_start => 3,
        },
    ])
    ->status_is(204);

$assignments->[1]->@{qw(device_id device_asset_tag)} = ();

$t->get_ok('/rack/'.$rack->id.'/assignment')
    ->status_is(200)
    ->json_schema_is('RackAssignments')
    ->json_is($assignments);

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
