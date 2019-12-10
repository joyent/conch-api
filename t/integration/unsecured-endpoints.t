use v5.26;
use warnings;

use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;
use Conch::UUID 'create_uuid_str';

my $t = Test::Conch->new;

$t->get_ok('/ping')
    ->status_is(200)
    ->json_schema_is('Ping')
    ->json_is({ status => 'ok' })
    ->header_exists('Request-Id')
    ->header_exists('X-Request-ID')
    ->header_is('X-Conch-API', $t->app->version_tag);

$t->get_ok('/me')->status_is(401);

$t->get_ok('/version')
    ->status_is(200)
    ->header_is('Last-Modified', $t->app->startup_time->strftime('%a, %d %b %Y %T GMT'))
    ->json_schema_is('Version')
    ->json_cmp_deeply({ version => re(qr/^v/) });

$t->get_ok('/foo/bar/baz')
    ->status_is(404)
    ->json_is({ error => 'Route Not Found' })
    ->log_error_is('no endpoint found for: GET /foo/bar/baz');

$t->post_ok('/boop?some_arg=1')
    ->status_is(404)
    ->json_is({ error => 'Route Not Found' })
    ->log_error_is('no endpoint found for: POST /boop');

$t->get_ok('/workspace')->status_is(401);
$t->get_ok('/workspace/'.create_uuid_str())->status_is(401);

$t->get_ok('/device/TEST')->status_is(401);
$t->post_ok('/device/TEST', json => { a => 'b' })->status_is(401);

$t->post_ok('/relay/TEST/register', json => { a => 'b' })->status_is(401);

$t->get_ok('/hardware_product')->status_is(401);
$t->get_ok('/hardware_product/'.create_uuid_str())->status_is(401);

$t->load_fixture_set('workspace_room_rack_layout', 0);
$t->load_fixture(qw(hardware_product_switch hardware_product_compute hardware_product_storage));

subtest 'device totals' => sub {
    my $global_ws_id = $t->app->db_workspaces->search({ name => 'GLOBAL' })->get_column('id')->single;
    my $hardware_product_rs = $t->app->db_hardware_products->active->hri;
    my $switch_vendor = $hardware_product_rs->search({ alias => 'Switch Vendor' })->single;
    my $test_compute = $hardware_product_rs->search({ alias => 'Test Compute' })->single;

    # find a rack
    my $rack = $t->app->db_racks->rows(1)->single;

    # create/update some rack layouts
    $rack->update_or_create_related('rack_layouts', $_, { key => 'rack_layout_rack_id_rack_unit_start_key' })
    foreach (
        {
            hardware_product_id => $switch_vendor->{id},
            rack_unit_start => 1,
        },
        {
            hardware_product_id => $test_compute->{id},
            rack_unit_start => 5,
        },
    );

    # create a few devices and locate them in this rack
    $t->app->db_devices->create($_) foreach (
        {
            serial_number => 'test switch',
            hardware_product_id => $switch_vendor->{id},
            health => 'fail',
            device_location => { rack_id => $rack->id, rack_unit_start => 1 },
        },
        {
            serial_number => 'test compute',
            hardware_product_id => $test_compute->{id},
            health => 'pass',
            device_location => { rack_id => $rack->id, rack_unit_start => 5 },
        },
    );

    # doctor the configs so they match the hw products we already have in the test data.
    $t->app->config({
        $t->app->config->%*,
        switch_aliases => [ 'Switch Vendor' ],
        server_aliases => [],
        storage_aliases => [ 'Test Storage' ],
        compute_aliases => [ 'Test Compute' ],
    });

    $t->get_ok("/workspace/123/device-totals")
        ->status_is(404);

    $t->get_ok("/workspace/$global_ws_id/device-totals")
        ->status_is(200)
        ->json_schema_is('DeviceTotals')
        ->json_is({
            all => [
                { alias => 'Switch Vendor', count => 1, health => 'fail' },
                { alias => 'Test Compute', count => 1, health => 'pass' }
            ],
            switches => [
                { alias => 'Switch Vendor', count => 1, health => 'fail' },
            ],
            servers => [
                { alias => 'Test Compute', count => 1, health => 'pass' }
            ],
            storage => [],
            compute => [
                { alias => 'Test Compute', count => 1, health => 'pass' }
            ],
        });

    $t->get_ok("/workspace/$global_ws_id/device-totals.circ")
        ->status_is(200)
        ->json_schema_is('DeviceTotalsCirconus')
        ->json_is({
            'Switch Vendor' => {
                health => { pass => 0, fail => 1, unknown => 0 },
                count => 1,
            },
            'Test Compute' => {
                health => { pass => 1, fail => 0, unknown => 0 },
                count => 1,
            },
            compute => { count => 1 },
        });
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
