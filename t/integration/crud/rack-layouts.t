use Mojo::Base -strict;
use Test::More;
use Test::Warnings;
use Test::Deep;
use Conch::UUID 'create_uuid_str';
use Test::Conch;

my $t = Test::Conch->new;
$t->load_fixture('super_user');

$t->authenticate;

$t->get_ok('/layout')
    ->status_is(200)
    ->json_schema_is('RackLayouts')
    ->json_is([]);

$t->load_fixture_set('workspace_room_rack_layout', $_) for 0..1; # contains compute, storage products
$t->load_fixture('hardware_product_switch');

my $hw_product_switch = $t->load_fixture('hardware_product_switch');    # rack_unit_size 1
my $hw_product_compute = $t->load_fixture('hardware_product_compute');  # rack_unit_size 2
my $hw_product_storage = $t->load_fixture('hardware_product_storage');  # rack_unit_size 4

# at the start, both racks have these assigned slots:
# start 1, width 2
# start 3, width 4
# start 11, width 4

my $fake_id = create_uuid_str();

$t->get_ok('/layout')
    ->status_is(200)
    ->json_schema_is('RackLayouts')
    ->json_cmp_deeply(bag(
        map +{
            $_->%*,
            id => re(Conch::UUID::UUID_FORMAT),
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            updated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        },
        (map +(
            { rack_id => $_, rack_unit_start => 1, rack_unit_size => 2, hardware_product_id => $hw_product_compute->id },
            { rack_id => $_, rack_unit_start => 3, rack_unit_size => 4, hardware_product_id => $hw_product_storage->id },
            { rack_id => $_, rack_unit_start => 11, rack_unit_size => 4, hardware_product_id => $hw_product_storage->id },
        ), my $rack_id = $t->load_fixture('rack_0a')->id, $t->load_fixture('rack_1a')->id)
    ));

my $initial_layouts = $t->tx->res->json;
my $layout_width_4 = $initial_layouts->[2];    # start 11, width 4.

$t->get_ok("/layout/$initial_layouts->[0]{id}")
    ->status_is(200)
    ->json_schema_is('RackLayout')
    ->json_is($initial_layouts->[0]);

$t->post_ok('/layout', json => { wat => 'wat' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/', message => re(qr/properties not allowed/i) } ]);

$t->get_ok("/rack/$rack_id/layouts")
    ->status_is(200)
    ->location_is('/rack/'.$rack_id.'/layouts')
    ->json_schema_is('RackLayouts')
    ->json_cmp_deeply([
        map +{
            $_->%*,
            id => re(Conch::UUID::UUID_FORMAT),
            rack_id => $rack_id,
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            updated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        },
        { rack_unit_start => 1, rack_unit_size => 2, hardware_product_id => $hw_product_compute->id },
        { rack_unit_start => 3, rack_unit_size => 4, hardware_product_id => $hw_product_storage->id },
        { rack_unit_start => 11, rack_unit_size => 4, hardware_product_id => $hw_product_storage->id },
    ]);

my $layout_1_2 = $t->load_fixture('rack_0a_layout_1_2');
$t->post_ok('/layout/'.$layout_1_2->id, json => { rack_unit_start => 43 })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'rack_unit_start beyond maximum' });

$t->post_ok('/layout/'.$layout_1_2->id, json => { rack_unit_start => 42 })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'rack_unit_start+rack_unit_size beyond maximum' });

$t->post_ok('/layout', json => {
        rack_id => $fake_id,
        hardware_product_id => $hw_product_compute->id,
        rack_unit_start => 1,
    })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'Rack does not exist' });

$t->post_ok('/layout', json => {
        rack_id => $rack_id,
        hardware_product_id => $fake_id,
        rack_unit_start => 1,
    })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'Hardware product does not exist' });

$t->post_ok('/layout', json => {
        rack_id => $rack_id,
        hardware_product_id => $hw_product_switch->id,
        rack_unit_start => 43,
    })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'rack_unit_start beyond maximum' });

$t->post_ok('/layout', json => {
        rack_id => $rack_id,
        hardware_product_id => $hw_product_storage->id,
        rack_unit_start => 42,
    })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'rack_unit_start+rack_unit_size beyond maximum' });

$t->post_ok('/layout', json => {
        rack_id => $rack_id,
        hardware_product_id => $hw_product_switch->id,
        rack_unit_start => 42,
    })
    ->status_is(303)
    ->location_like(qr!^/layout/${\Conch::UUID::UUID_FORMAT}$!);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('RackLayout');

$t->post_ok('/layout', json => {
        rack_id => $rack_id,
        hardware_product_id => $hw_product_switch->id,
        rack_unit_start => 42,
    })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'rack_unit_start conflict' });

# the start of this product will overlap with assigned slots (need 12-15, 11-14 are assigned)
$t->post_ok('/layout', json => {
        rack_id => $rack_id,
        hardware_product_id => $hw_product_storage->id,
        rack_unit_start => 12,
    })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'rack_unit_start conflict' });

# the end of this product will overlap with assigned slots (need 10-13, 11-14 are assigned)
$t->post_ok('/layout', json => {
        rack_id => $rack_id,
        hardware_product_id => $hw_product_storage->id,
        rack_unit_start => 10,
    })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'rack_unit_start conflict' });


# at the moment, we have these assigned slots:
# start 1, width 2
# start 3, width 4
# start 11, width 4
# start 42, width 1

my $rack = $t->app->db_racks->search({ 'rack.id' => $rack_id })->prefetch('datacenter_room')->single;
my $room = $rack->datacenter_room;

$t->get_ok($_)
    ->status_is(200)
    ->location_is('/rack/'.$rack_id.'/layouts')
    ->json_schema_is('RackLayouts')
    ->json_cmp_deeply([
        map +{
            $_->%*,
            id => re(Conch::UUID::UUID_FORMAT),
            rack_id => $rack_id,
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            updated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        },
        { rack_unit_start => 1, rack_unit_size => 2, hardware_product_id => $hw_product_compute->id },
        { rack_unit_start => 3, rack_unit_size => 4, hardware_product_id => $hw_product_storage->id },
        { rack_unit_start => 11, rack_unit_size => 4, hardware_product_id => $hw_product_storage->id },
        { rack_unit_start => 42, rack_unit_size => 1, hardware_product_id => $hw_product_switch->id },
    ])
    foreach
        '/rack/'.$rack_id.'/layouts',
        '/rack/'.$room->vendor_name.':'.$rack->name.'/layouts',
        '/room/'.$room->id.'/rack/'.$rack->id.'/layouts',
        '/room/'.$room->id.'/rack/'.$room->vendor_name.':'.$rack->name.'/layouts',
        '/room/'.$room->id.'/rack/'.$rack->name.'/layouts',
        '/room/'.$room->alias.'/rack/'.$rack->id.'/layouts',
        '/room/'.$room->alias.'/rack/'.$room->vendor_name.':'.$rack->name.'/layouts',
        '/room/'.$room->alias.'/rack/'.$rack->name.'/layouts';

my $layout_3_6 = $t->load_fixture('rack_0a_layout_3_6');

# can't move a layout to a new rack
$t->post_ok('/layout/'.$layout_3_6->id,
        json => { rack_id => $t->load_fixture('rack_1a')->id })
    ->status_is(400)
    ->json_is({ error => 'changing rack_id is not permitted' });

# can't put something into an assigned position
$t->post_ok('/layout/'.$layout_3_6->id, json => { rack_unit_start => 11 })
    ->status_is(409)
    ->json_is({ error => 'rack_unit_start conflict' });

# the start of this product will overlap with assigned slots (need 12-15, 11-14 are assigned)
$t->post_ok('/layout/'.$layout_3_6->id, json => { rack_unit_start => 12 })
    ->status_is(409)
    ->json_is({ error => 'rack_unit_start conflict' });

# the end of this product will overlap with assigned slots (need 10-13, 11-14 are assigned)
$t->post_ok('/layout/'.$layout_1_2->id,
        json => { rack_unit_start => 10, hardware_product_id => $hw_product_storage->id })
    ->status_is(409)
    ->json_is({ error => 'rack_unit_start conflict' });

$t->post_ok('/layout/'.$layout_1_2->id,
        json => { rack_unit_start => 19, hardware_product_id => $hw_product_storage->id })
    ->status_is(303)
    ->location_is('/layout/'.$layout_1_2->id);

my $layout_19_22 = $layout_1_2;
undef $layout_1_2;

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_is('/rack_unit_start' => 19)
    ->json_schema_is('RackLayout');

# now we have these assigned slots:
# start 3, width 4
# start 11, width 4
# start 19, width 4     originally start 1, width 2
# start 42, width 1

$t->get_ok("/rack/$rack_id/layouts")
    ->status_is(200)
    ->location_is('/rack/'.$rack_id.'/layouts')
    ->json_schema_is('RackLayouts')
    ->json_cmp_deeply([
        superhashof({ rack_id => $rack_id, rack_unit_start => 3, hardware_product_id => $hw_product_storage->id }),
        superhashof({ rack_id => $rack_id, rack_unit_start => 11, hardware_product_id => $hw_product_storage->id }),
        superhashof({ rack_id => $rack_id, rack_unit_start => 19, hardware_product_id => $hw_product_storage->id }),
        superhashof({ rack_id => $rack_id, rack_unit_start => 42, hardware_product_id => $hw_product_switch->id }),
    ]);

$t->post_ok('/layout/'.$layout_19_22->id, json => { hardware_product_id => $fake_id })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'Hardware product does not exist' });

$t->post_ok('/layout', json => {
        rack_id => $rack_id,
        hardware_product_id => $hw_product_compute->id,
        rack_unit_start => 1,
    })
    ->status_is(303)
    ->location_like(qr!^/layout/${\Conch::UUID::UUID_FORMAT}$!);

# now we have these assigned slots:
# start 1, width 2
# start 3, width 4
# start 11, width 4
# start 19, width 4     originally start 1, width 2
# start 42, width 1

$t->get_ok("/rack/$rack_id/layouts")
    ->status_is(200)
    ->location_is('/rack/'.$rack_id.'/layouts')
    ->json_schema_is('RackLayouts')
    ->json_cmp_deeply([
        superhashof({ rack_id => $rack_id, rack_unit_start => 1, hardware_product_id => $hw_product_compute->id }),
        superhashof({ rack_id => $rack_id, rack_unit_start => 3, hardware_product_id => $hw_product_storage->id }),
        superhashof({ rack_id => $rack_id, rack_unit_start => 11, hardware_product_id => $hw_product_storage->id }),
        superhashof({ rack_id => $rack_id, rack_unit_start => 19, hardware_product_id => $hw_product_storage->id }),
        superhashof({ rack_id => $rack_id, rack_unit_start => 42, hardware_product_id => $hw_product_switch->id }),
    ]);

# slide a layout forward, overlapping with itself
$t->post_ok('/layout/'.$layout_19_22->id, json => { rack_unit_start => 20 })
    ->status_is(303)
    ->location_is('/layout/'.$layout_19_22->id);

my $layout_20_23 = $layout_19_22;
undef $layout_19_22;

# now we have these assigned slots:
# start 1, width 2
# start 3, width 4
# start 11, width 4
# start 20, width 4     originally start 1, width 2
# start 42, width 1

$t->get_ok("/rack/$rack_id/layouts")
    ->status_is(200)
    ->location_is('/rack/'.$rack_id.'/layouts')
    ->json_schema_is('RackLayouts')
    ->json_cmp_deeply([
        superhashof({ rack_unit_start => 1, hardware_product_id => $hw_product_compute->id }),
        superhashof({ rack_unit_start => 3, hardware_product_id => $hw_product_storage->id }),
        superhashof({ rack_unit_start => 11, hardware_product_id => $hw_product_storage->id }),
        superhashof({ rack_unit_start => 20, hardware_product_id => $hw_product_storage->id }),
        superhashof({ rack_unit_start => 42, hardware_product_id => $hw_product_switch->id }),
    ]);


my $device = $hw_product_storage->create_related('devices', {
    serial_number => 'my device',
    health => 'unknown',
    device_location => { rack_id => $rack_id, rack_unit_start => 20 },
});

# try to move layout from 20-23 back to 19-22
$t->post_ok('/layout/'.$layout_20_23->id, json => { rack_unit_start => 19 })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'cannot update a layout with a device occupying it' });

$t->delete_ok('/layout/'.$layout_20_23->id)
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'cannot delete a layout with a device occupying it' });

$t->delete_ok('/layout/'.$layout_3_6->id)
    ->status_is(204);
$t->get_ok('/layout/'.$layout_3_6->id)
    ->status_is(404)
    ->log_debug_is('Could not find rack layout '.$layout_3_6->id);

# now we have these assigned slots:
# start 1, width 2
# start 11, width 4
# start 20, width 4     # occupied by 'my device'
# start 42, width 1

$t->post_ok('/rack/'.$rack_id.'/layouts',
        json => [{ rack_unit_start => 1, hardware_product_id => create_uuid_str }])
    ->status_is(409)
    ->json_cmp_deeply({ error => re(qr/^hardware_product_id ${\Conch::UUID::UUID_FORMAT} does not exist$/) });

$t->post_ok('/rack/'.$rack_id.'/layouts',
        json => [{ rack_unit_start => 42, hardware_product_id => $hw_product_compute->id }])
    ->status_is(409)
    ->json_is({ error => 'layout starting at rack_unit 42 will extend beyond the end of the rack' });

$t->post_ok('/rack/'.$rack_id.'/layouts',
        json => [
            { rack_unit_start => 1, hardware_product_id => $hw_product_compute->id },
            { rack_unit_start => 2, hardware_product_id => $hw_product_compute->id },
        ])
    ->status_is(409)
    ->json_is({ error => 'layouts starting at rack_units 1 and 2 overlap' });

$t->post_ok('/rack/'.$rack_id.'/layouts',
        json => [
            # unchanged
            { rack_unit_start => 1, hardware_product_id => $hw_product_compute->id },
            # unchanged, and has a located device
            { rack_unit_start => 20, hardware_product_id => $hw_product_storage->id },
            # new layout
            { rack_unit_start => 26, hardware_product_id => $hw_product_compute->id },
        ])
    ->status_is(303)
    ->location_is('/rack/'.$rack_id.'/layouts')
    ->log_debug_is('deleted 2 rack layouts, created 1 rack layouts for rack '.$rack_id);

$t->get_ok('/rack/'.$rack_id.'/layouts')
    ->status_is(200)
    ->location_is('/rack/'.$rack_id.'/layouts')
    ->json_schema_is('RackLayouts')
    ->json_cmp_deeply([
        superhashof({ rack_unit_start => 1, hardware_product_id => $hw_product_compute->id }),
        superhashof({ rack_unit_start => 20, hardware_product_id => $hw_product_storage->id }),
        superhashof({ rack_unit_start => 26, hardware_product_id => $hw_product_compute->id }),
    ]);

$t->get_ok('/rack/'.$rack_id.'/assignment')
    ->status_is(200)
    ->json_schema_is('RackAssignments')
    ->json_cmp_deeply([
        { rack_unit_start => 1, rack_unit_size => 2, hardware_product_name => $hw_product_compute->name, device_id => undef, device_asset_tag => undef },
        { rack_unit_start => 20, rack_unit_size => 4, hardware_product_name => $hw_product_storage->name, device_id => $device->id, device_asset_tag => undef },
        { rack_unit_start => 26, rack_unit_size => 2, hardware_product_name => $hw_product_compute->name, device_id => undef, device_asset_tag => undef },
    ]);

$t->post_ok('/rack/'.$rack_id.'/layouts',
        json => [
            { rack_unit_start => 3, hardware_product_id => $hw_product_compute->id },
        ])
    ->status_is(303)
    ->location_is('/rack/'.$rack_id.'/layouts')
    ->log_debug_is('unlocated 1 devices, deleted 3 rack layouts, created 1 rack layouts for rack '.$rack_id);

$t->get_ok('/rack/'.$rack_id.'/layouts')
    ->status_is(200)
    ->location_is('/rack/'.$rack_id.'/layouts')
    ->json_schema_is('RackLayouts')
    ->json_cmp_deeply([
        superhashof({ rack_unit_start => 3, hardware_product_id => $hw_product_compute->id }),
    ]);

$t->get_ok('/rack/'.$rack_id.'/assignment')
    ->status_is(200)
    ->json_schema_is('RackAssignments')
    ->json_cmp_deeply([
        { rack_unit_start => 3, rack_unit_size => 2, hardware_product_name => $hw_product_compute->name, device_id => undef, device_asset_tag => undef },
    ]);

$t->post_ok('/rack/'.$rack_id.'/layouts', json => [])
    ->status_is(303)
    ->location_is('/rack/'.$rack_id.'/layouts')
    ->log_debug_is('deleted 1 rack layouts for rack '.$rack_id);

$t->get_ok('/rack/'.$rack_id.'/layouts')
    ->status_is(200)
    ->location_is('/rack/'.$rack_id.'/layouts')
    ->json_schema_is('RackLayouts')
    ->json_is([]);

$t->get_ok('/rack/'.$rack_id.'/assignment')
    ->status_is(200)
    ->json_schema_is('RackAssignments')
    ->json_is([]);

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
