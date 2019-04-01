use v5.26;
use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;
use Data::UUID;

my $t = Test::Conch->new;
$t->load_fixture_set('workspace_room_rack_layout', 0);

my $global_ws_id = $t->load_fixture('conch_user_global_workspace')->workspace_id;
my $sub_ws_id = $t->load_fixture('sub_workspace_0')->id;
my $rack = $t->load_fixture('rack_0a');
my $rack_id = $rack->id;
my $room = $t->load_fixture('datacenter_room_0a');
my $hardware_product_compute = $t->load_fixture('hardware_product_compute');
my $hardware_product_storage = $t->load_fixture('hardware_product_storage');

my $uuid = Data::UUID->new;

# this rack is reachable through GLOBAL (via the room) but not through the sub-workspace.
my $rack2 = $rack->datacenter_room->add_to_racks({
    name => 'second rack',
    rack_role_id => $rack->rack_role_id,
});

$t->authenticate;

$t->get_ok("/workspace/$global_ws_id/rack")
    ->status_is(200)
    ->json_schema_is('WorkspaceRackSummary')
    ->json_cmp_deeply({
        'room-0a' => bag(
            {
                id => $rack_id,
                name => 'rack 0a',
                role => 'rack_role 42U',
                size => 42,
                device_progress => {},
            },
            {
                id => $rack2->id,
                name => 'second rack',
                role => 'rack_role 42U',
                size => 42,
                device_progress => {},
            },
         ),
    });

$t->get_ok("/workspace/$global_ws_id/rack/notauuid")
    ->status_is(400)
    ->json_cmp_deeply({ error => re(qr/must be a UUID/) });

$t->get_ok("/workspace/$global_ws_id/rack/" . $uuid->create_str())
    ->status_is(404);

subtest 'Add rack to workspace' => sub {
    $t->post_ok("/workspace/$sub_ws_id/rack")
        ->status_is(400, 'Requires request body')
        ->json_cmp_deeply({ error => re(qr/Expected object/) });

    $t->post_ok("/workspace/$sub_ws_id/rack", json => {
            id => $rack_id,
            serial_number => 'abc',
            asset_tag => 'deadbeef',
        })
        ->status_is(303)
        ->location_is("/workspace/$sub_ws_id/rack/$rack_id");

    $t->get_ok("/workspace/$sub_ws_id/rack")
        ->status_is(200)
        ->json_schema_is('WorkspaceRackSummary')
        ->json_is({
            'room-0a' => [
                {
                    id => $rack_id,
                    name => 'rack 0a',
                    role => 'rack_role 42U',
                    size => 42,
                    device_progress => {},
                },
             ],
        });

    $t->get_ok("/workspace/$sub_ws_id/rack/$rack_id")
        ->status_is(200)
        ->json_schema_is('WorkspaceRack')
        ->json_cmp_deeply({
            id => $rack_id,
            name => 'rack 0a',
            role => 'rack_role 42U',
            # TODO? size => 42,
            datacenter => $room->az,
            slots => [
                {
                    id => ignore,
                    name => $hardware_product_compute->name,
                    alias => $hardware_product_compute->alias,
                    vendor => $hardware_product_compute->hardware_vendor->name,
                    rack_unit_start => 1,
                    size => 2,
                    occupant => undef,
                },
                {
                    id => ignore,
                    name => $hardware_product_storage->name,
                    alias => $hardware_product_storage->alias,
                    vendor => $hardware_product_storage->hardware_vendor->name,
                    rack_unit_start => 3,
                    size => 4,
                    occupant => undef,
                },
                {
                    id => ignore,
                    name => $hardware_product_storage->name,
                    alias => $hardware_product_storage->alias,
                    vendor => $hardware_product_storage->hardware_vendor->name,
                    rack_unit_start => 11,
                    size => 4,
                    occupant => undef,
                },
            ],
        });

    $t->get_ok("/workspace/$global_ws_id/rack/$rack_id" => { Accept => 'text/csv' })
        ->status_is(200)
        ->content_is(<<CSV);
az,rack_name,rack_unit_start,hardware_name,device_asset_tag,device_serial_number
room-0a,"rack 0a",1,${\ $hardware_product_compute->name},,
room-0a,"rack 0a",3,${\ $hardware_product_storage->name},,
room-0a,"rack 0a",11,${\ $hardware_product_storage->name},,
CSV


    subtest 'Cannot modify GLOBAL workspace' => sub {
        $t->post_ok("/workspace/$global_ws_id/rack", json => { id => $rack_id })
            ->status_is(400)
            ->json_is({ error => 'Cannot modify GLOBAL workspace' });
    };
};

subtest 'Assign device to a location' => sub {
    $t->post_ok("/workspace/$sub_ws_id/rack/$rack_id/layout", json => { TEST => 42 })
        ->status_is(409)
        ->json_is({ error => "slot 42 does not exist in the layout for rack $rack_id" });

    $t->post_ok("/workspace/$sub_ws_id/rack/$rack_id/layout",
            json => { TEST => 1, NEW_DEVICE => 3 })
        ->status_is(200)
        ->json_schema_is('WorkspaceRackLayoutUpdateResponse')
        ->json_cmp_deeply({ updated => bag('TEST', 'NEW_DEVICE') });

    ok(
        !$t->app->db_devices->search({ id => 'TEST' })->devices_without_location->exists,
        'device is now located',
    );

    $t->get_ok('/device/TEST/location')
        ->status_is(200)
        ->json_schema_is('DeviceLocation');

    $t->get_ok("/workspace/$sub_ws_id/rack/$rack_id")
        ->status_is(200)
        ->json_schema_is('WorkspaceRack')
        ->json_cmp_deeply({
            id => $rack_id,
            name => 'rack 0a',
            role => 'rack_role 42U',
            # TODO? size => 42,
            datacenter => $room->az,
            slots => [
                {
                    id => ignore,
                    name => $hardware_product_compute->name,
                    alias => $hardware_product_compute->alias,
                    vendor => $hardware_product_compute->hardware_vendor->name,
                    rack_unit_start => 1,
                    size => 2,
                    occupant => superhashof({ id => 'TEST' }),
                },
                {
                    id => ignore,
                    name => $hardware_product_storage->name,
                    alias => $hardware_product_storage->alias,
                    vendor => $hardware_product_storage->hardware_vendor->name,
                    rack_unit_start => 3,
                    size => 4,
                    occupant => superhashof({ id => 'NEW_DEVICE' }),
                },
                {
                    id => ignore,
                    name => $hardware_product_storage->name,
                    alias => $hardware_product_storage->alias,
                    vendor => $hardware_product_storage->hardware_vendor->name,
                    rack_unit_start => 11,
                    size => 4,
                    occupant => undef,
                },
            ],
        });

    $t->get_ok("/workspace/$sub_ws_id/rack/$rack_id" => { Accept => 'text/csv' })
        ->status_is(200)
        ->content_is(<<CSV);
az,rack_name,rack_unit_start,hardware_name,device_asset_tag,device_serial_number
room-0a,"rack 0a",1,${\ $hardware_product_compute->name},,TEST
room-0a,"rack 0a",3,${\ $hardware_product_storage->name},,NEW_DEVICE
room-0a,"rack 0a",11,${\ $hardware_product_storage->name},,
CSV

    $t->post_ok('/device/NEW_DEVICE/validated')
        ->status_is(303);

    $t->get_ok("/workspace/$sub_ws_id/rack")
        ->status_is(200)
        ->json_schema_is('WorkspaceRackSummary')
        ->json_is({
            'room-0a' => [
                {
                    device_progress => { UNKNOWN => 1, VALID => 1 },
                    id => $rack_id,
                    name => 'rack 0a',
                    role => 'rack_role 42U',
                    size => 42,
                }
             ]
        });
};

subtest 'Remove rack from workspace' => sub {
    $t->delete_ok("/workspace/$sub_ws_id/rack/$rack_id")
        ->status_is(204);

    $t->get_ok("/workspace/$sub_ws_id/rack/$rack_id")
        ->status_is(404);

    $t->post_ok("/workspace/$global_ws_id/rack", json => { id => $rack_id })
        ->status_is(400)
        ->json_is({ error => 'Cannot modify GLOBAL workspace' });
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
