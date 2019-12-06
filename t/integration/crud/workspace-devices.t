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
    id          => $t->load_fixture('hardware_product_compute')->validation_plan_id,
    name        => 'our plan',
    description => 'Test Plan',
    validations => [ 'Conch::Validation::DeviceProductName' ],
}]);

$t->load_fixture('super_user');
my $global_ws_id = $t->load_fixture('global_workspace')->id;
my @layouts = $t->load_fixture(map 'rack_0a_layout_'.$_, '1_2', '3_6');

my @devices = map $t->app->db_devices->create($_), (
    {
        serial_number => 'TEST',
        hardware_product_id => $layouts[0]->hardware_product_id,
        health => 'pass',
        device_location => { map +($_ => $layouts[0]->$_), qw(rack_id rack_unit_start) },
    },
    {
        serial_number => 'DEVICE1',
        hardware_product_id => $layouts[1]->hardware_product_id,
        health => 'unknown',
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
            name     => 'test relay',
        })
    ->status_is(201);

my $report = path('t/integration/resource/passing-device-report.json')->slurp_utf8;
$t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $report)
    ->status_is(200)
    ->json_schema_is('ValidationStateWithResults')
    ->json_is('/device_id', $devices[0]->id);

$t->post_ok('/device/'.$devices[0]->id.'/validated')
    ->status_is(303)
    ->location_is('/device/'.$devices[0]->id);

$t->get_ok("/workspace/$global_ws_id/device")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_cmp_deeply([
        superhashof({
            id => $devices[0]->id,
            validated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            last_seen => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            health => 'pass',
        }),
        superhashof({
            id => $devices[1]->id,
            validated => undef,
            last_seen => undef,
            health => 'unknown',
        }),
    ]);

my $devices_data = $t->tx->res->json;

$t->get_ok("/workspace/$global_ws_id/device?validated=0")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is([ $devices_data->[1] ]);

$t->get_ok("/workspace/$global_ws_id/device?validated=1")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is([ $devices_data->[0] ]);

$t->get_ok("/workspace/$global_ws_id/device?health=fail")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is([]);

$t->get_ok("/workspace/$global_ws_id/device?health=pass")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is([ $devices_data->[0] ]);

$t->get_ok("/workspace/$global_ws_id/device?health=unknown")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is([ $devices_data->[1] ]);

$t->get_ok("/workspace/$global_ws_id/device?health=pass&health=unknown")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is($devices_data);

$t->get_ok("/workspace/$global_ws_id/device?health=bunk")
    ->status_is(400)
    ->json_schema_is('QueryParamsValidationError')
    ->json_cmp_deeply('/details', [ { path => '/health', message => re(qr/not in enum list/i) } ]);

$t->get_ok("/workspace/$global_ws_id/device?ids_only=1&serials_only=1")
    ->status_is(400)
    ->json_schema_is('QueryParamsValidationError')
    ->json_cmp_deeply('/details', [ { path => '/', message => re(qr{should not match}i) } ]);

$t->get_ok("/workspace/$global_ws_id/device?ids_only=1")
    ->status_is(200)
    ->json_schema_is('DeviceIds')
    ->json_is([$devices[0]->id, $devices[1]->id]);

$t->get_ok("/workspace/$global_ws_id/device?serials_only=1")
    ->status_is(200)
    ->json_schema_is('DeviceSerials')
    ->json_is([$devices[0]->serial_number, $devices[1]->serial_number]);

$t->get_ok("/workspace/$global_ws_id/device?ids_only=1&health=pass")
    ->status_is(200)
    ->json_schema_is('DeviceIds')
    ->json_is([$devices[0]->id]);

$t->get_ok("/workspace/$global_ws_id/device?active_minutes=5")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is([ $devices_data->[0] ]);

$t->get_ok("/workspace/$global_ws_id/device?active_minutes=5&validated=1")
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is([ $devices_data->[0] ]);

subtest 'Devices with PXE data' => sub {
    $t->app->db_device_neighbors->delete;
    $t->app->db_device_nics->delete;
    $t->app->db_device_nics->create($_) foreach (
        {
            device_id => $devices[0]->id,
            state => 'up',
            iface_name => 'milhouse',
            iface_type => 'human',
            iface_vendor => 'Groening',
            mac => '00:00:00:00:00:aa',
            ipaddr => '0.0.0.1',
        },
        {
            device_id => $devices[0]->id,
            state => 'up',
            iface_name => 'ned',
            iface_type => 'human',
            iface_vendor => 'Groening',
            mac => '00:00:00:00:00:bb',
            ipaddr => '0.0.0.2',
        },
        {
            device_id => $devices[0]->id,
            state => undef,
            iface_name => 'ipmi1',
            iface_type => 'human',
            iface_vendor => 'Groening',
            mac => '00:00:00:00:00:cc',
            ipaddr => '0.0.0.3',
        },
    );

    $t->get_ok('/workspace/'.$global_ws_id.'/device/pxe')
        ->status_is(200)
        ->json_schema_is('WorkspaceDevicePXEs')
        ->json_cmp_deeply([
            {
                id => $devices[0]->id,
                phase => 'integration',
                location => {
                    az => 'room-0a',
                    datacenter_room => 'room 0a',
                    rack => 'ROOM:0.A:rack.0a',
                    rack_unit_start => $layouts[0]->rack_unit_start,
                    target_hardware_product => superhashof({ alias => $layouts[0]->hardware_product->alias }),
                },
                ipmi => {
                    mac => '00:00:00:00:00:cc',
                    ip => '0.0.0.3',
                },
                pxe => {
                    mac => '00:00:00:00:00:aa',
                },
            },
            {
                id => $devices[1]->id,
                phase => 'integration',
                location => {
                    az => 'room-0a',
                    datacenter_room => 'room 0a',
                    rack => 'ROOM:0.A:rack.0a',
                    rack_unit_start => $layouts[1]->rack_unit_start,
                    target_hardware_product => superhashof({ alias => $layouts[1]->hardware_product->alias }),
                },
                ipmi => undef,
                pxe => undef,
            },
        ]);
    my $pxe_data = $t->tx->res->json;

    $devices[0]->update({ phase => 'production' });
    delete $pxe_data->[0]{location};
    $pxe_data->[0]{phase} = 'production';

    # in this case, we omit the entire result... because we cannot possibly include the device
    # and not its location, because it is only present in the workspace via rack.
    $t->get_ok('/workspace/'.$global_ws_id.'/device/pxe')
        ->status_is(200)
        ->json_schema_is('WorkspaceDevicePXEs')
        ->json_is([ $pxe_data->[1] ]);

    $t->get_ok('/workspace/'.$global_ws_id.'/device/pxe?phase_earlier_than=')
        ->status_is(200)
        ->json_schema_is('WorkspaceDevicePXEs')
        ->json_is($pxe_data);
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
