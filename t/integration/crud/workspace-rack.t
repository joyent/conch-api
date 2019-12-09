use v5.26;
use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;

my $t = Test::Conch->new;
$t->load_fixture('super_user');
my $global_ws_id = $t->load_fixture('global_workspace')->id;

$t->authenticate;

$t->get_ok('/workspace/'.$global_ws_id.'/rack')
    ->status_is(200)
    ->json_schema_is('WorkspaceRackSummary')
    ->json_is({});

$t->load_fixture_set('workspace_room_rack_layout', 0);

my $sub_ws_id = $t->load_fixture('sub_workspace_0')->id;
my $rack = $t->load_fixture('rack_0a');
my $rack_id = $rack->id;
my $room = $t->load_fixture('datacenter_room_0a');
my $hardware_product_compute = $t->load_fixture('hardware_product_compute');
my $hardware_product_storage = $t->load_fixture('hardware_product_storage');

# this rack is reachable through GLOBAL (via the room) but not through the sub-workspace.
my $rack2 = $rack->datacenter_room->add_to_racks({
    name => 'second rack',
    rack_role_id => $rack->rack_role_id,
});

$t->get_ok("/workspace/$global_ws_id/rack")
    ->status_is(200)
    ->json_schema_is('WorkspaceRackSummary')
    ->json_cmp_deeply({
        'room-0a' => [
            {
                id => $rack_id,
                name => 'rack.0a',
                phase => 'integration',
                rack_role_name => 'rack_role 42U',
                rack_size => 42,
                device_progress => {},
            },
            {
                id => $rack2->id,
                name => 'second rack',
                phase => 'integration',
                rack_role_name => 'rack_role 42U',
                rack_size => 42,
                device_progress => {},
            },
        ],
    });

subtest 'Add rack to workspace' => sub {
    $t->post_ok("/workspace/$sub_ws_id/rack")
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', [ { path => '/', message => re(qr/expected object/i) } ]);

    $t->post_ok("/workspace/$sub_ws_id/rack", json => {
            id => $rack_id,
            serial_number => 'abc',
            asset_tag => 'deadbeef',
        })
        ->status_is(303)
        ->location_is("/workspace/$sub_ws_id/rack");

    $t->get_ok("/workspace/$sub_ws_id/rack")
        ->status_is(200)
        ->json_schema_is('WorkspaceRackSummary')
        ->json_is({
            'room-0a' => [
                {
                    id => $rack_id,
                    name => 'rack.0a',
                    phase => 'integration',
                    rack_role_name => 'rack_role 42U',
                    rack_size => 42,
                    device_progress => {},
                },
             ],
        });

    $t->post_ok("/workspace/$global_ws_id/rack", json => { id => $rack_id })
        ->status_is(400)
        ->json_is({ error => 'Cannot modify GLOBAL workspace' });
};

subtest 'Assign device to a location' => sub {
    $t->post_ok('/rack/'.$rack_id.'/assignment',
            json => [ { device_serial_number => 'TEST', rack_unit_start => 42 } ])
        ->status_is(409)
        ->json_is({ error => 'missing layout for rack_unit_start 42' });

    $t->post_ok('/rack/'.$rack_id.'/assignment', json => [
            { device_serial_number => 'TEST', rack_unit_start => 1 },
            { device_serial_number => 'NEW_DEVICE', rack_unit_start => 3 },
        ])
        ->status_is(303)
        ->location_is('/rack/'.$rack_id.'/assignment');

    my $test = $t->app->db_devices->find({ serial_number => 'TEST' });
    my $new_device = $t->app->db_devices->find({ serial_number => 'NEW_DEVICE' });
    ok(
        !$test->self_rs->devices_without_location->exists,
        'device is now located',
    );

    $t->get_ok('/device/TEST/location')
        ->status_is(200)
        ->json_schema_is('DeviceLocation')
        ->json_cmp_deeply({
            rack => superhashof({ id => $rack_id }),
            rack_unit_start => 1,
            datacenter_room => superhashof({ datacenter_id => $rack->datacenter_room->datacenter_id }),
            datacenter => superhashof({ id => $rack->datacenter_room->datacenter_id }),
            target_hardware_product => {
                (map +($_ => $hardware_product_compute->$_), qw(id name alias sku hardware_vendor_id)),
            },
        });

    $t->get_ok('/rack/'.$rack_id.'/assignment')
        ->status_is(200)
        ->json_schema_is('RackAssignments')
        ->json_is([
            {
                rack_unit_start => 1,
                rack_unit_size => 2,
                device_id => $test->id,
                device_asset_tag => undef,
                hardware_product_name => $hardware_product_compute->name,
            },
            {
                rack_unit_start => 3,
                rack_unit_size => 4,
                device_id => $new_device->id,
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

    $t->post_ok('/device/NEW_DEVICE/validated')
        ->status_is(303)
        ->location_is('/device/'.$new_device->id);

    $t->get_ok("/workspace/$sub_ws_id/rack")
        ->status_is(200)
        ->json_schema_is('WorkspaceRackSummary')
        ->json_is({
            'room-0a' => [
                {
                    device_progress => { unknown => 1, valid => 1 },
                    id => $rack_id,
                    phase => 'integration',
                    name => 'rack.0a',
                    rack_role_name => 'rack_role 42U',
                    rack_size => 42,
                }
             ]
        });
};

subtest 'Remove rack from workspace' => sub {
    $t->delete_ok("/workspace/$sub_ws_id/rack/$rack_id")
        ->status_is(204)
        ->log_debug_is('deleted workspace_rack entry for workspace_id '.$sub_ws_id.' and rack_id '.$rack_id);

    $t->delete_ok("/workspace/$sub_ws_id/rack/$rack_id")
        ->status_is(404)
        ->log_debug_is('Could not find rack '.$rack_id.' in or beneath workspace '.$sub_ws_id);

    $t->get_ok("/workspace/$sub_ws_id/rack")
        ->status_is(200)
        ->json_schema_is('WorkspaceRackSummary')
        ->json_is({});

    $t->post_ok("/workspace/$global_ws_id/rack", json => { id => $rack_id })
        ->status_is(400)
        ->json_is({ error => 'Cannot modify GLOBAL workspace' });
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
