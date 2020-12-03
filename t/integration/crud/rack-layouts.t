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

$t->load_fixture_set('universe_room_rack_layout', $_) for 0..1; # contains compute, storage products
$t->load_fixture('hardware_product_switch');

my $hw_product_switch = $t->load_fixture('hardware_product_switch');    # rack_unit_size 1
my $hw_product_compute = $t->load_fixture('hardware_product_compute');  # rack_unit_size 2
my $hw_product_storage = $t->load_fixture('hardware_product_storage');  # rack_unit_size 4

# at the start, both racks have these assigned slots:
# start 1, width 2
# start 3, width 4
# start 11, width 4

my $fake_id = create_uuid_str();
my @racks = $t->app->db_racks->search({ name => [qw(rack.0a rack.1a)] })->prefetch('datacenter_room')->order_by('name')->all;
my $rack_id = $racks[0]->id;

$t->get_ok('/layout')
    ->status_is(200)
    ->json_schema_is('RackLayouts')
    ->json_cmp_deeply([
        map +{
            $_->%*,
            id => re(Conch::UUID::UUID_FORMAT),
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            updated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        },
        (map +(
            {
                rack_id => $_->id,
                rack_name => $_->datacenter_room->vendor_name.':'.$_->name,
                rack_unit_start => 1,
                rack_unit_size => 2,
                hardware_product_id => $hw_product_compute->id,
                sku => $hw_product_compute->sku,
            },
            {
                rack_id => $_->id,
                rack_name => $_->datacenter_room->vendor_name.':'.$_->name,
                rack_unit_start => 3,
                rack_unit_size => 4,
                hardware_product_id => $hw_product_storage->id,
                sku => $hw_product_storage->sku,
            },
            {
                rack_id => $_->id,
                rack_name => $_->datacenter_room->vendor_name.':'.$_->name,
                rack_unit_start => 11,
                rack_unit_size => 4,
                hardware_product_id => $hw_product_storage->id,
                sku => $hw_product_storage->sku,
            },
        ), @racks)
    ]);

my $initial_layouts = $t->tx->res->json;
my $layout_width_4 = $initial_layouts->[2];    # start 11, width 4.

$t->get_ok($_)
    ->status_is(200)
    ->json_schema_is('RackLayout')
    ->json_is($initial_layouts->[0])
    ->log_debug_is('Found rack layout '.(split('/'))[-1].((split('/'))[1] eq 'rack' ? ' in rack id '.(split('/'))[2] : ''))
    foreach
        '/layout/'.$initial_layouts->[0]{id},
        '/rack/'.$racks[0]->id.'/layout/'.$initial_layouts->[0]{id},
        '/rack/'.$racks[0]->id.'/layout/1';

$t->get_ok('/layout/1')
    ->status_is(400)
    ->json_is({ error => 'cannot look up layout by rack_unit_start without qualifying by rack' });

$t->post_ok('/layout', json => { wat => 'wat' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [
        superhashof({ error => 'missing properties: rack_id, hardware_product_id, rack_unit_start' }),
        superhashof({ error => 'additional property not permitted' }),
    ]);

$t->get_ok("/rack/$rack_id/layout")
    ->status_is(200)
    ->location_is('/rack/'.$rack_id.'/layout')
    ->json_schema_is('RackLayouts')
    ->json_cmp_deeply([
        map +{
            $_->%*,
            id => re(Conch::UUID::UUID_FORMAT),
            rack_id => $rack_id,
            rack_name => 'ROOM:0.A:rack.0a',
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            updated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        },
        { rack_unit_start => 1, rack_unit_size => 2, hardware_product_id => $hw_product_compute->id, sku => $hw_product_compute->sku },
        { rack_unit_start => 3, rack_unit_size => 4, hardware_product_id => $hw_product_storage->id, sku => $hw_product_storage->sku },
        { rack_unit_start => 11, rack_unit_size => 4, hardware_product_id => $hw_product_storage->id, sku => $hw_product_storage->sku },
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
    ->status_is(201)
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
    ->location_is('/rack/'.$rack_id.'/layout')
    ->json_schema_is('RackLayouts')
    ->json_cmp_deeply([
        map +{
            $_->%*,
            id => re(Conch::UUID::UUID_FORMAT),
            rack_id => $rack_id,
            rack_name => 'ROOM:0.A:rack.0a',
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            updated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        },
        { rack_unit_start => 1, rack_unit_size => 2, hardware_product_id => $hw_product_compute->id, sku => $hw_product_compute->sku },
        { rack_unit_start => 3, rack_unit_size => 4, hardware_product_id => $hw_product_storage->id, sku => $hw_product_storage->sku },
        { rack_unit_start => 11, rack_unit_size => 4, hardware_product_id => $hw_product_storage->id, sku => $hw_product_storage->sku },
        { rack_unit_start => 42, rack_unit_size => 1, hardware_product_id => $hw_product_switch->id, sku => $hw_product_switch->sku },
    ])
    foreach
        '/rack/'.$rack_id.'/layout',
        '/rack/'.$room->vendor_name.':'.$rack->name.'/layout',
        '/room/'.$room->id.'/rack/'.$rack->id.'/layout',
        '/room/'.$room->id.'/rack/'.$room->vendor_name.':'.$rack->name.'/layout',
        '/room/'.$room->id.'/rack/'.$rack->name.'/layout',
        '/room/'.$room->alias.'/rack/'.$rack->id.'/layout',
        '/room/'.$room->alias.'/rack/'.$room->vendor_name.':'.$rack->name.'/layout',
        '/room/'.$room->alias.'/rack/'.$rack->name.'/layout';

my $layout_3_6 = $t->load_fixture('rack_0a_layout_3_6');

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
    ->status_is(204)
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

$t->get_ok("/rack/$rack_id/layout")
    ->status_is(200)
    ->location_is('/rack/'.$rack_id.'/layout')
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
    ->status_is(201)
    ->location_like(qr!^/layout/${\Conch::UUID::UUID_FORMAT}$!);

# now we have these assigned slots:
# start 1, width 2
# start 3, width 4
# start 11, width 4
# start 19, width 4     originally start 1, width 2
# start 42, width 1

$t->get_ok("/rack/$rack_id/layout")
    ->status_is(200)
    ->location_is('/rack/'.$rack_id.'/layout')
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
    ->status_is(204)
    ->location_is('/layout/'.$layout_19_22->id);

my $layout_20_23 = $layout_19_22;
undef $layout_19_22;

# now we have these assigned slots:
# start 1, width 2
# start 3, width 4
# start 11, width 4
# start 20, width 4     originally start 1, width 2
# start 42, width 1

$t->get_ok("/rack/$rack_id/layout")
    ->status_is(200)
    ->location_is('/rack/'.$rack_id.'/layout')
    ->json_schema_is('RackLayouts')
    ->json_cmp_deeply([
        superhashof({ rack_unit_start => 1, hardware_product_id => $hw_product_compute->id }),
        superhashof({ rack_unit_start => 3, hardware_product_id => $hw_product_storage->id }),
        superhashof({ rack_unit_start => 11, hardware_product_id => $hw_product_storage->id }),
        superhashof({ rack_unit_start => 20, hardware_product_id => $hw_product_storage->id }),
        superhashof({ rack_unit_start => 42, hardware_product_id => $hw_product_switch->id }),
    ]);


# note that the hardware_product does not match the layout
my $device = $hw_product_compute->create_related('devices', {
    serial_number => 'my_device',
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
# start 20, width 4     # occupied by 'my_device'
# start 42, width 1

# cannot change the hardware_product to something totally different
$t->post_ok('/layout/'.$layout_20_23->id, json => { hardware_product_id => $hw_product_switch->id })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'cannot update a layout with a device occupying it' });

# cannot change the hardware_product_id and rack_unit_start at the same time
$t->post_ok('/layout/'.$layout_20_23->id,
        json => { rack_unit_start => 5, hardware_product_id => $hw_product_compute->id })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'cannot update a layout with a device occupying it' });

# can change just the hardware_product_id, as long as it matches the occupying device
$t->post_ok('/layout/'.$layout_20_23->id, json => { hardware_product_id => $hw_product_compute->id })
    ->status_is(204)
    ->location_is('/layout/'.$layout_20_23->id);

$t->post_ok('/rack/'.$rack_id.'/layout',
        json => [{ rack_unit_start => 1, hardware_product_id => create_uuid_str }])
    ->status_is(409)
    ->json_cmp_deeply({ error => re(qr/^hardware_product_id ${\Conch::UUID::UUID_FORMAT} does not exist$/) });

$t->post_ok('/rack/'.$rack_id.'/layout',
        json => [{ rack_unit_start => 42, hardware_product_id => $hw_product_compute->id }])
    ->status_is(409)
    ->json_is({ error => 'layout starting at rack_unit 42 will extend beyond the end of the rack' });

$t->post_ok('/rack/'.$rack_id.'/layout',
        json => [
            { rack_unit_start => 1, hardware_product_id => $hw_product_compute->id },
            { rack_unit_start => 2, hardware_product_id => $hw_product_compute->id },
        ])
    ->status_is(409)
    ->json_is({ error => 'layouts starting at rack_units 1 and 2 overlap' });

$t->post_ok('/rack/'.$rack_id.'/layout',
        json => [
            # unchanged
            { rack_unit_start => 1, hardware_product_id => $hw_product_compute->id },
            # unchanged, and has a located device
            { rack_unit_start => 20, hardware_product_id => $hw_product_compute->id },
            # new layout
            { rack_unit_start => 26, hardware_product_id => $hw_product_storage->id },
        ])
    ->status_is(204)
    ->location_is('/rack/'.$rack_id.'/layout')
    ->log_debug_is('deleted 2 rack layouts, created 1 rack layouts for rack '.$rack_id);

$t->get_ok('/rack/'.$rack_id.'/layout')
    ->status_is(200)
    ->location_is('/rack/'.$rack_id.'/layout')
    ->json_schema_is('RackLayouts')
    ->json_cmp_deeply([
        superhashof({ rack_unit_start => 1, hardware_product_id => $hw_product_compute->id }),
        superhashof({ rack_unit_start => 20, hardware_product_id => $hw_product_compute->id }),
        superhashof({ rack_unit_start => 26, hardware_product_id => $hw_product_storage->id }),
    ]);

$t->get_ok('/rack/'.$rack_id.'/assignment')
    ->status_is(200)
    ->json_schema_is('RackAssignments')
    ->json_cmp_deeply([
        {
            rack_unit_start => 1,
            rack_unit_size => 2,
            hardware_product_name => $hw_product_compute->name,
            sku => $hw_product_compute->sku,
            device_id => undef,
            device_serial_number => undef,
            device_asset_tag => undef,
        },
        {
            rack_unit_start => 20,
            rack_unit_size => 2,
            hardware_product_name => $hw_product_compute->name,
            sku => $hw_product_compute->sku,
            device_id => $device->id,
            device_serial_number => $device->serial_number,
            device_asset_tag => undef,
        },
        {
            rack_unit_start => 26,
            rack_unit_size => 4,
            hardware_product_name => $hw_product_storage->name,
            sku => $hw_product_storage->sku,
            device_id => undef,
            device_serial_number => undef,
            device_asset_tag => undef,
        },
    ]);

$t->post_ok('/rack/'.$rack_id.'/layout',
        json => [
            { rack_unit_start => 3, hardware_product_id => $hw_product_compute->id },
        ])
    ->status_is(204)
    ->location_is('/rack/'.$rack_id.'/layout')
    ->log_debug_is('unlocated 1 devices, deleted 3 rack layouts, created 1 rack layouts for rack '.$rack_id);

$t->get_ok('/rack/'.$rack_id.'/layout')
    ->status_is(200)
    ->location_is('/rack/'.$rack_id.'/layout')
    ->json_schema_is('RackLayouts')
    ->json_cmp_deeply([
        superhashof({ rack_unit_start => 3, hardware_product_id => $hw_product_compute->id }),
    ]);

$t->get_ok('/rack/'.$rack_id.'/assignment')
    ->status_is(200)
    ->json_schema_is('RackAssignments')
    ->json_cmp_deeply([
        {
            rack_unit_start => 3,
            rack_unit_size => 2,
            hardware_product_name => $hw_product_compute->name,
            sku => $hw_product_compute->sku,
            device_id => undef,
            device_serial_number => undef,
            device_asset_tag => undef,
        },
    ]);

$t->post_ok('/rack/'.$rack_id.'/layout', json => [])
    ->status_is(204)
    ->location_is('/rack/'.$rack_id.'/layout')
    ->log_debug_is('deleted 1 rack layouts for rack '.$rack_id);

$t->get_ok('/rack/'.$rack_id.'/layout')
    ->status_is(200)
    ->location_is('/rack/'.$rack_id.'/layout')
    ->json_schema_is('RackLayouts')
    ->json_is([]);

$t->get_ok('/rack/'.$rack_id.'/assignment')
    ->status_is(200)
    ->json_schema_is('RackAssignments')
    ->json_is([]);

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
