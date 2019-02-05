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
my $rack_id = $t->load_fixture('datacenter_rack_0a')->id;
my $hardware_product_compute_name = $t->load_fixture('hardware_product_compute')->name;
my $hardware_product_storage_name = $t->load_fixture('hardware_product_storage')->name;

my $uuid = Data::UUID->new;

# remove room from the sub-workspace
$t->load_fixture('workspace_room_0a')->delete;

$t->authenticate;

$t->get_ok("/workspace/$global_ws_id/rack")
    ->status_is(200)
    ->json_schema_is('WorkspaceRackSummary');

$t->get_ok("/workspace/$global_ws_id/rack/notauuid")
    ->status_is(400)
    ->json_like('/error', qr/must be a UUID/);
$t->get_ok("/workspace/$global_ws_id/rack/" . $uuid->create_str())
    ->status_is(404);

subtest 'Add rack to workspace' => sub {
    $t->post_ok("/workspace/$sub_ws_id/rack")
        ->status_is(400, 'Requires request body')
        ->json_like('/error', qr/Expected object/);

    $t->post_ok("/workspace/$sub_ws_id/rack", json => {
            id => $rack_id,
            serial_number => 'abc',
            asset_tag => 'deadbeef',
        })
        ->status_is(303)
        ->location_is("/workspace/$sub_ws_id/rack/$rack_id");

    $t->get_ok("/workspace/$sub_ws_id/rack")
        ->status_is(200)
        ->json_schema_is('WorkspaceRackSummary');

    $t->get_ok("/workspace/$sub_ws_id/rack/$rack_id")
        ->status_is(200)
        ->json_schema_is('WorkspaceRack');

    subtest 'Cannot modify GLOBAL workspace' => sub {
        $t->post_ok("/workspace/$global_ws_id/rack", json => { id => $rack_id })
            ->status_is(400)
            ->json_is({ error => 'Cannot modify GLOBAL workspace' });
    };
};

subtest 'Remove rack from workspace' => sub {
    $t->delete_ok("/workspace/$sub_ws_id/rack/$rack_id")
        ->status_is(204);

    $t->get_ok("/workspace/$sub_ws_id/rack/$rack_id")
        ->status_is(404)
        ->json_like('/error', qr/not found/);

    $t->post_ok("/workspace/$global_ws_id/rack", json => { id => $rack_id })
        ->status_is(400)
        ->json_is({ error => 'Cannot modify GLOBAL workspace' });
};

subtest 'Assign device to a location' => sub {
    $t->post_ok("/workspace/$global_ws_id/rack/$rack_id/layout", json => { TEST => 42 })
        ->status_is(409)
        ->json_is({ error => "slot 42 does not exist in the layout for rack $rack_id" });

    $t->post_ok("/workspace/$global_ws_id/rack/$rack_id/layout",
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

    $t->get_ok("/workspace/$global_ws_id/rack/$rack_id")
        ->status_is(200)
        ->json_schema_is('WorkspaceRack')
        ->json_is(
            '/slots/0/rack_unit_start', 1,
            '/slots/0/occupant/id', 'TEST',
            '/slots/1/rack_unit_start', 3,
            '/slots/1/occupant/id', 'NEW_DEVICE',
        );

    $t->get_ok("/workspace/$global_ws_id/rack/$rack_id" => { Accept => 'text/csv' })
        ->status_is(200)
        ->content_like(qr/^az,rack_name,rack_unit_start,hardware_name,device_asset_tag,device_serial_number$/m)
        ->content_like(qr/^room-0a,"rack 0a",1,$hardware_product_compute_name,,TEST$/m)
        ->content_like(qr/^room-0a,"rack 0a",3,$hardware_product_storage_name,,NEW_DEVICE$/m)
        ->content_like(qr/^room-0a,"rack 0a",11,$hardware_product_storage_name,,$/m);

    $t->get_ok("/workspace/$global_ws_id/rack")
        ->status_is(200)
        ->json_schema_is('WorkspaceRackSummary')
        ->json_is({
            'room-0a' => [
                {
                    device_progress => { UNKNOWN => 2 },
                    id => $rack_id,
                    name => 'rack 0a',
                    role => 'rack_role 42U',
                    size => 42,
                }
             ]
        });
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
