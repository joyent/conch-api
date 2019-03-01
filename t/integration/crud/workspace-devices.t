use v5.26;
use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Warnings;
use Path::Tiny;
use Test::Deep;
use Test::Conch;

my $t = Test::Conch->new;

$t->load_fixture_set('workspace_room_rack_layout', 0);
$t->load_validation_plans([{
    name        => 'Conch v1 Legacy Plan: Server',
    description => 'Test Plan',
    validations => [ 'Conch::Validation::DeviceProductName' ],
}]);

my $global_ws_id = $t->load_fixture('conch_user_global_workspace')->workspace_id;
my @layouts = $t->load_fixture(qw(rack_0a_layout_1_2 rack_0a_layout_3_6));

my $new_device = $t->app->db_devices->create($_) foreach (
    {
        id => 'TEST',
        hardware_product_id => $layouts[0]->hardware_product_id,
        state => 'UNKNOWN',
        health => 'PASS',
        device_location => { map +($_ => $layouts[0]->$_), qw(rack_id rack_unit_start) },
    },
    {
        id => 'NEW_DEVICE',
        hardware_product_id => $layouts[1]->hardware_product_id,
        state => 'UNKNOWN',
        health => 'UNKNOWN',
        device_location => { map +($_ => $layouts[1]->$_), qw(rack_id rack_unit_start) },
    },
);

$t->authenticate;

$t->post_ok('/relay/deadbeef/register',
    json => {
        serial   => 'deadbeef',
        version  => '0.0.1',
        ipaddr   => '127.0.0.1',
        ssh_port => 22,
        alias    => 'test relay',
    }
)->status_is(204)->content_is('');

my $report = path('t/integration/resource/passing-device-report.json')->slurp_utf8;
$t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $report)
    ->status_is(200)
    ->json_schema_is('ValidationStateWithResults');

foreach my $query ('/device/TEST/graduate', '/device/TEST/validated') {
    $t->post_ok($query)
        ->status_is(303)
        ->location_is('/device/TEST');
}

$t->get_ok("/workspace/$global_ws_id/device")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_cmp_deeply([
        superhashof({
            id => 'TEST',
            graduated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            validated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            last_seen => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            health => 'PASS',
        }),
        superhashof({
            id => 'NEW_DEVICE',
            graduated => undef,
            validated => undef,
            last_seen => undef,
            health => 'UNKNOWN',
        }),
    ]);

my $devices_data = $t->tx->res->json;

$t->get_ok("/workspace/$global_ws_id/device?graduated=f")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is('', [ $devices_data->[1] ]);

$t->get_ok("/workspace/$global_ws_id/device?graduated=F")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is('', [ $devices_data->[1] ]);

$t->get_ok("/workspace/$global_ws_id/device?graduated=t")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is('', [ $devices_data->[0] ]);

$t->get_ok("/workspace/$global_ws_id/device?graduated=T")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is('', [ $devices_data->[0] ]);

$t->get_ok("/workspace/$global_ws_id/device?validated=f")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is('', [ $devices_data->[1] ]);

$t->get_ok("/workspace/$global_ws_id/device?validated=F")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is('', [ $devices_data->[1] ]);

$t->get_ok("/workspace/$global_ws_id/device?validated=t")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is('', [ $devices_data->[0] ]);

$t->get_ok("/workspace/$global_ws_id/device?validated=T")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is('', [ $devices_data->[0] ]);

$t->get_ok("/workspace/$global_ws_id/device?health=fail")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is('', []);

$t->get_ok("/workspace/$global_ws_id/device?health=FAIL")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is('', []);

$t->get_ok("/workspace/$global_ws_id/device?health=pass")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is('', [ $devices_data->[0] ]);

$t->get_ok("/workspace/$global_ws_id/device?health=PASS")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is('', [ $devices_data->[0] ]);

$t->get_ok("/workspace/$global_ws_id/device?health=unknown")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is('', [ $devices_data->[1] ]);

$t->get_ok("/workspace/$global_ws_id/device?health=pass&graduated=t")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is('', [ $devices_data->[0] ]);

$t->get_ok("/workspace/$global_ws_id/device?health=pass&graduated=f")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is('', []);

$t->get_ok("/workspace/$global_ws_id/device?ids_only=1")
    ->status_is(200)
    ->json_is(['TEST', 'NEW_DEVICE']);

$t->get_ok("/workspace/$global_ws_id/device?ids_only=1&health=pass")
    ->status_is(200)
    ->json_is(['TEST']);

$t->get_ok("/workspace/$global_ws_id/device?active=t")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is('', [ $devices_data->[0] ]);

$t->get_ok("/workspace/$global_ws_id/device?active=t&graduated=t")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is('', [ $devices_data->[0] ]);

# /device/active redirects to /device so first make sure there is a redirect,
# then follow it and verify the results
subtest 'Redirect /workspace/:id/device/active' => sub {
    $t->get_ok("/workspace/$global_ws_id/device/active")
        ->status_is(302)
        ->location_is("/workspace/$global_ws_id/device?active=t");

    my $temp = $t->ua->max_redirects;
    $t->ua->max_redirects(1);

    $t->get_ok("/workspace/$global_ws_id/device/active")
        ->status_is(200)
        ->json_schema_is('Devices')
        ->json_is('', [ $devices_data->[0] ]);

    $t->ua->max_redirects($temp);
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
