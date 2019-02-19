use v5.26;
use warnings;

use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;

my $t = Test::Conch->new;
$t->load_fixture('legacy_datacenter');

$t->get_ok('/ping')
    ->status_is(200)
    ->json_is({ status => 'ok' });

$t->get_ok('/version')
    ->status_is(200)
    ->json_cmp_deeply({ version => re(qr/^v/) });


subtest 'device totals' => sub {

    # TODO: DBIx::Class::EasyFixture can make this nicer across lots of tests.

    my $global_ws_id = $t->app->db_workspaces->search({ name => 'GLOBAL' })->get_column('id')->single;
    my $hardware_product_rs = $t->app->db_hardware_products->active->hri;
    my $farce = $hardware_product_rs->search({ alias => 'Farce 10' })->single;
    my $test_compute = $hardware_product_rs->search({ alias => 'Test Compute' })->single;

    # find a rack
    my $rack = $t->app->db_racks->search(undef, { rows => 1 })->single;

    # add the rack to the global workspace
    $rack->create_related('workspace_racks' => { workspace_id => $global_ws_id });

    # create/update some rack layouts
    $rack->update_or_create_related('rack_layouts', $_, { key => 'rack_layout_rack_id_rack_unit_start_key' })
    foreach (
        {
            hardware_product_id => $farce->{id},
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
            id => 'test farce',
            hardware_product_id => $farce->{id},
            state => 'ignore',
            health => 'FAIL',
            device_location => { rack_id => $rack->id, rack_unit_start => 1 },
        },
        {
            id => 'test compute',
            hardware_product_id => $test_compute->{id},
            state => 'ignore',
            health => 'PASS',
            device_location => { rack_id => $rack->id, rack_unit_start => 5 },
        },
    );

    # doctor the configs so they match the hw products we already have in the test data.
    $t->app->stash('config')->%* = (
        $t->app->stash('config')->%*,
        switch_aliases => [ 'Farce 10' ],
        server_aliases => [],
        storage_aliases => [ 'Test Storage' ],
        compute_aliases => [ 'Test Compute' ],
    );

    $t->get_ok("/workspace/123/device-totals")
        ->status_is(404);

    $t->get_ok("/workspace/$global_ws_id/device-totals")
        ->status_is(200)
        ->json_schema_is('DeviceTotals')
        ->json_is({
            all => [
                { alias => 'Farce 10', count => 1, health => 'FAIL' },
                { alias => 'Test Compute', count => 1, health => 'PASS' }
            ],
            switches => [
                { alias => 'Farce 10', count => 1, health => 'FAIL' },
            ],
            servers => [
                { alias => 'Test Compute', count => 1, health => 'PASS' }
            ],
            storage => [],
            compute => [
                { alias => 'Test Compute', count => 1, health => 'PASS' }
            ],
        });

    $t->get_ok("/workspace/$global_ws_id/device-totals.circ")
        ->status_is(200)
        ->json_schema_is('DeviceTotalsCirconus')
        ->json_is({
            'Farce 10' => {
                health => { PASS => 0, FAIL => 1, UNKNOWN => 0 },
                count => 1,
            },
            'Test Compute' => {
                health => { PASS => 1, FAIL => 0, UNKNOWN => 0 },
                count => 1,
            },
            compute => { count => 1 },
        });
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
