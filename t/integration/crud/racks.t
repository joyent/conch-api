use Mojo::Base -strict, -signatures;
use Test::More;
use Test::Warnings;
use Test::Deep;
use Conch::UUID 'create_uuid_str';
use Test::Conch;
use List::Util 'first';

my $t = Test::Conch->new;
$t->load_fixture('super_user');

$t->authenticate;

$t->get_ok('/rack')
    ->status_is(200)
    ->json_schema_is('Racks')
    ->json_is([]);

$t->load_fixture_set('workspace_room_rack_layout', 0);
my $build = $t->generate_fixtures('build');

my $fake_id = create_uuid_str();

my $rack = $t->load_fixture('rack_0a');

$t->get_ok('/rack')
    ->status_is(200)
    ->json_schema_is('Racks')
    ->json_cmp_deeply([ superhashof({ name => 'rack.0a' }) ]);

$t->get_ok('/rack/'.$rack->id)
    ->status_is(200)
    ->json_schema_is('Rack')
    ->json_cmp_deeply(superhashof({ name => 'rack.0a' }));

$t->post_ok('/rack', json => { wat => 'wat' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/', message => re(qr/properties not allowed/i) } ]);

$t->post_ok('/rack', json => { name => 'r4ck', datacenter_room_id => $fake_id, build_id => $fake_id })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/rack_role_id', message => re(qr/missing property/i) } ]);

$t->post_ok('/rack', json => { name => 'r4ck', rack_role_id => $fake_id, build_id => $fake_id })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/datacenter_room_id', message => re(qr/missing property/i) } ]);

$t->post_ok('/rack', json => { name => 'r4ck', rack_role_id => $fake_id, datacenter_room_id => $fake_id })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/build_id', message => re(qr/missing property/i) } ]);

$t->post_ok('/rack', json => {
        name => 'r4ck',
        datacenter_room_id => $fake_id,
        rack_role_id => $rack->rack_role_id,
        build_id => $build->id,
    })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'Room does not exist' });

$t->post_ok('/rack', json => {
        name => 'r4ck',
        datacenter_room_id => $rack->datacenter_room_id,
        rack_role_id => $fake_id,
        build_id => $build->id,
    })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'Rack role does not exist' });

$t->post_ok('/rack', json => {
        name => 'r4ck',
        datacenter_room_id => $rack->datacenter_room_id,
        rack_role_id => $rack->rack_role_id,
        build_id => $fake_id,
    })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'Build does not exist' });

$t->post_ok('/rack', json => { map +($_ => $rack->$_), qw(name datacenter_room_id rack_role_id build_id) })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'The room already contains a rack named '.$rack->name });

$t->post_ok('/rack', json => {
        name => 'r4ck',
        datacenter_room_id => $rack->datacenter_room_id,
        rack_role_id => $rack->rack_role_id,
        serial_number => 'abc',
        build_id => $build->id,
    })
    ->status_is(303)
    ->location_like(qr!^/rack/${\Conch::UUID::UUID_FORMAT}$!);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('Rack')
    ->json_cmp_deeply({
        id => re(Conch::UUID::UUID_FORMAT),
        name => 'r4ck',
        datacenter_room_id => $rack->datacenter_room_id,
        rack_role_id => $rack->rack_role_id,
        serial_number => 'abc',
        asset_tag => undef,
        phase => 'integration',
        created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        updated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        build_id => $build->id,
    });
my $new_rack_id = $t->tx->res->json->{id};

my $small_rack_role = $t->app->db_rack_roles->create({ name => '10U', rack_size => 10 });

$t->post_ok('/rack/'.$rack->id, json => { datacenter_room_id => create_uuid_str() })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'Room does not exist' });

$t->post_ok('/rack/'.$rack->id, json => { rack_role_id => create_uuid_str() })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'Rack role does not exist' });

$t->post_ok('/rack/'.$rack->id, json => { build_id => create_uuid_str() })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'Build does not exist' });

my $duplicate_rack = first { $_->isa('Conch::DB::Result::Rack') } $t->generate_fixtures('rack');
$duplicate_rack->update({ name => $rack->name });

$t->post_ok('/rack/'.$rack->id, json => { datacenter_room_id => $duplicate_rack->datacenter_room_id })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'New room already contains a rack named '.$rack->name });

$duplicate_rack->update({ name => 'something else', datacenter_room_id => $rack->datacenter_room_id });

$t->post_ok('/rack/'.$duplicate_rack->id, json => { name => $rack->name })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'The room already contains a rack named '.$rack->name });

$t->post_ok('/rack/'.$rack->id, json => { rack_role_id => $small_rack_role->id })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'cannot resize rack: found an assigned rack layout that extends beyond the new rack_size' });

$t->post_ok("/rack/$new_rack_id", json => {
        name => 'rack',
        serial_number => 'abc',
        asset_tag => 'deadbeef',
    })
    ->status_is(303)
    ->location_is('/rack/'.$new_rack_id);

$t->post_ok("/rack/$new_rack_id", json => { rack_role_id => $small_rack_role->id })
    ->status_is(303)
    ->location_is('/rack/'.$new_rack_id);

$t->post_ok("/rack/$new_rack_id", json => { rack_role_id => $small_rack_role->id })
    ->status_is(303)
    ->location_is('/rack/'.$new_rack_id);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('Rack')
    ->json_cmp_deeply(superhashof({ name => 'rack', serial_number => 'abc', asset_tag => 'deadbeef' }));

$t->get_ok("/rack/$new_rack_id/assignment")
    ->status_is(200)
    ->json_schema_is('RackAssignments')
    ->json_is([]);

$t->delete_ok('/rack/'.$rack->id)
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'cannot delete a rack when a rack_layout is referencing it' });

my $null_user = $t->generate_fixtures('user_account');
my $t2 = Test::Conch->new(pg => $t->pg);
$t2->authenticate(email => $null_user->email);
$t2->delete_ok("/rack/$new_rack_id")
    ->status_is(403)
    ->log_debug_is('User lacks the required role (rw) for rack '.$new_rack_id);

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
            hardware_product_name => $hardware_product_compute->name,
        },
        {
            rack_unit_start => 3,
            rack_unit_size => 4,
            device_id => undef,
            device_asset_tag => undef,
            hardware_product_name => $hardware_product_storage->name,
        },
        {
            rack_unit_start => 11,
            rack_unit_size => 4,
            device_id => undef,
            device_asset_tag => undef,
            hardware_product_name => $hardware_product_storage->name,
        },
    ]);
my $assignments = $t->tx->res->json;

$t->post_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_serial_number => 'FOO', # new device
            rack_unit_start => 2,
        },
    ])
    ->status_is(409)
    ->json_is({ error => 'missing layout for rack_unit_start 2' });

my ($bar) = $t->generate_fixtures(device => { hardware_product_id => $hardware_product_storage->id });

$t->post_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_serial_number => 'FOO', # new device
            device_asset_tag => 'ohhai',
            rack_unit_start => 1,
        },
        {
            device_id => $bar->id, # existing device
            device_serial_number => 'BAR',
            device_asset_tag => 'hello',
            rack_unit_start => 3,
        },
    ])
    ->status_is(303)
    ->location_is('/rack/'.$rack->id.'/assignment');

my $foo = $t->app->db_devices->find({ serial_number => 'FOO' });

$assignments->[0]->@{qw(device_id device_asset_tag)} = ($foo->id,'ohhai');
$assignments->[1]->@{qw(device_id device_asset_tag)} = ($bar->id,'hello');

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
            { id => $foo->id, phase => 'integration' },
            { id => $bar->id, phase => 'integration' },
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
            { id => $foo->id, phase => 'integration' },
            { id => $bar->id, phase => 'integration' },
        ),
        'all assigned devices are still in the integration phase',
    );

    $t->post_ok('/rack/'.$rack->id.'/phase', json => { phase => 'production' })
        ->status_is(303)
        ->location_is('/rack/'.$rack->id);

    cmp_deeply(
        [ $device_phase_rs->all ],
        bag(
            { id => $foo->id, phase => 'production' },
            { id => $bar->id, phase => 'production' },
        ),
        'all assigned devices are moved to the production phase',
    );
};

$t->post_ok('/rack/'.$rack->id.'/assignment', json => [
        { device_id => $foo->id, rack_unit_start => 11 },
        { device_id => $foo->id, rack_unit_start => 13 },
    ])
    ->status_is(400)
    ->json_is({ error => 'duplication of devices is not permitted' });

$t->post_ok('/rack/'.$rack->id.'/assignment', json => [
        { device_serial_number => 'FOO', rack_unit_start => 11 },
        { device_serial_number => 'FOO', rack_unit_start => 13 },
    ])
    ->status_is(400)
    ->json_is({ error => 'duplication of devices is not permitted' });

$t->post_ok('/rack/'.$rack->id.'/assignment', json => [
        { device_id => $foo->id, rack_unit_start => 11 },
        { device_serial_number => 'FOO', rack_unit_start => 13 },
    ])
    ->status_is(400)
    ->json_is({ error => 'duplication of devices is not permitted' });

$t->post_ok('/rack/'.$rack->id.'/assignment', json => [
        { device_serial_number => 'FOO', rack_unit_start => 11 },
        { device_serial_number => 'BAR', rack_unit_start => 11 },
    ])
    ->status_is(400)
    ->json_is({ error => 'duplication of rack_unit_starts is not permitted' });

my $new_id = create_uuid_str();
$t->post_ok('/rack/'.$rack->id.'/assignment', json => [
        { device_id => $new_id, rack_unit_start => 11 },
    ])
    ->status_is(404)
    ->log_is('no device corresponding to device id '.$new_id);

$t->post_ok('/rack/'.$rack->id.'/assignment', json => [
        { device_id => $foo->id, device_serial_number => 'BAR', rack_unit_start => 11 },
    ])
    ->status_is(400)
    ->log_is(re(qr/unique constraint.*serial_number/));

# current layout:
# slot 1, tag=ohhai - FOO = new device
# slot 3, tag=hello - BAR = existing device.
# slot 11, empty.

# devices exchange serials atomically
$t->post_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_id => $foo->id,
            device_serial_number => 'BAR',  # previous serial = FOO
            rack_unit_start => 1,
        },
        {
            device_id => $bar->id,
            device_serial_number => 'FOO',  # previous serial = BAR
            rack_unit_start => 3,
        },
    ])
    ->status_is(303)
    ->location_is('/rack/'.$rack->id.'/assignment');

$foo->discard_changes;
$bar->discard_changes;
cmp_deeply(
    [ map $_->serial_number, $foo, $bar],
    [ qw(BAR FOO) ],
    'FOO and BAR exchanged serials atomically',
);

# undo that change, for the sanity of our variable names...
$t->app->schema->txn_do(sub {
    $t->app->schema->storage->dbh_do(sub ($, $dbh) { $dbh->do('set constraints all deferred') });
    $foo->update({ serial_number => 'FOO' });
    $bar->update({ serial_number => 'BAR' });
});

$t->get_ok('/rack/'.$rack->id.'/assignment')
    ->status_is(200)
    ->json_schema_is('RackAssignments')
    ->json_is($assignments);


my @device_locations = $rack->device_locations->order_by('rack_unit_start')->hri;

# devices exchange locations atomically
$t->post_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_id => $bar->id,  # previous occupant: FOO
            rack_unit_start => 1,
        },
        {
            device_id => $foo->id,  # previous occupant: BAR
            rack_unit_start => 3,
        },
    ])
    ->status_is(303)
    ->location_is('/rack/'.$rack->id.'/assignment');

$assignments->@[0,1] = (
    { $assignments->[0]->%*, $assignments->[1]->%{qw(device_id device_asset_tag)} },
    { $assignments->[1]->%*, $assignments->[0]->%{qw(device_id device_asset_tag)} },
);

$t->get_ok('/rack/'.$rack->id.'/assignment')
    ->status_is(200)
    ->json_schema_is('RackAssignments')
    ->json_is($assignments);

cmp_deeply(
    [ $rack->device_locations->order_by('rack_unit_start')->hri->get_column('created')->all ],
    [ map $_->{created}, @device_locations ],
    'previous device_location records are preserved during the swap',
);

# move FOO from rack unit 3 to rack unit 1; evicting the existing occupant of 1; 3 is now empty
# BAZ is created and put in rack unit 11.
$t->post_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_serial_number => 'FOO',
            rack_unit_start => 1,
        },
        {
            device_serial_number => 'BAZ',
            rack_unit_start => 11,
        },
    ])
    ->status_is(303)
    ->location_is('/rack/'.$rack->id.'/assignment');

my $baz = $t->app->db_devices->find({ serial_number => 'BAZ' });

$assignments->[0]->@{qw(device_id device_asset_tag)} = $assignments->[1]->@{qw(device_id device_asset_tag)};
$assignments->[1]->@{qw(device_id device_asset_tag)} = (undef, undef);
$assignments->[2]->{device_id} = $baz->id;

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('RackAssignments')
    ->json_is($assignments);

ok(!$t->app->db_device_locations->search({ device_id => $bar->id })->exists, 'previous occupant is now homeless');

$t->delete_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_id => $foo->id,
            rack_unit_start => 2,   # this rack_unit_start doesn't exist
        },
    ])
    ->status_is(404);

$t->delete_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_id => $foo->id,
            rack_unit_start => 3,   # this slot isn't occupied
        },
    ])
    ->status_is(404);

$t->delete_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_id => $foo->id,
            rack_unit_start => 11,  # wrong slot for this device
        },
    ])
    ->status_is(404);

$t->delete_ok('/rack/'.$rack->id.'/assignment', json => [
        {
            device_id => $foo->id,
            rack_unit_start => 1,
        },
    ])
    ->status_is(204);

$assignments->[0]->@{qw(device_id device_asset_tag)} = ();

$t->get_ok('/rack/'.$rack->id.'/assignment')
    ->status_is(200)
    ->json_schema_is('RackAssignments')
    ->json_is($assignments);

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
