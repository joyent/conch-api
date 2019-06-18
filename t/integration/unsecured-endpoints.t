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
    ->header_exists('X-Request-ID');

$t->get_ok('/me')->status_is(401);

$t->get_ok('/version')
    ->status_is(200)
    ->json_schema_is('Version')
    ->json_cmp_deeply({ version => re(qr/^v/) });

$t->get_ok('/workspace')->status_is(401);
$t->get_ok('/workspace/'.create_uuid_str())->status_is(401);

$t->get_ok('/device/TEST')->status_is(401);
$t->post_ok('/device/TEST', json => { a => 'b' })->status_is(401);

$t->post_ok('/relay/TEST/register', json => { a => 'b' })->status_is(401);

$t->get_ok('/hardware_product')->status_is(401);
$t->get_ok('/hardware_product/'.create_uuid_str())->status_is(401);

$t->load_fixture('legacy_datacenter');

subtest 'device totals' => sub {

    # TODO: DBIx::Class::EasyFixture can make this nicer across lots of tests.

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
            id => 'test switch',
            hardware_product_id => $switch_vendor->{id},
            state => 'ignore',
            health => 'fail',
            device_location => { rack_id => $rack->id, rack_unit_start => 1 },
        },
        {
            id => 'test compute',
            hardware_product_id => $test_compute->{id},
            state => 'ignore',
            health => 'pass',
            device_location => { rack_id => $rack->id, rack_unit_start => 5 },
        },
    );

    # doctor the configs so they match the hw products we already have in the test data.
    $t->app->stash('config')->%* = (
        $t->app->stash('config')->%*,
        switch_aliases => [ 'Switch Vendor' ],
        server_aliases => [],
        storage_aliases => [ 'Test Storage' ],
        compute_aliases => [ 'Test Compute' ],
    );

    $t->get_ok("/workspace/123/device-totals")
        ->status_is(404);

    # note this response type uses lower-cased health values.
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

    # note this response type uses upper-cased health values.
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
