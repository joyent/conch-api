use v5.26;
use warnings;

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

my $rack_id = $t->load_fixture('datacenter_rack_0a')->id;
my $hardware_product_id = $t->load_fixture('hardware_product_compute')->id;

$t->authenticate;

$t->get_ok('/device/nonexistent')
    ->status_is(404)
    ->json_schema_is('Error')
    ->json_is({ error => 'Not found' });

subtest 'unlocated device' => sub {
    $t->post_ok(
        '/relay/deadbeef/register',
        json => {
            serial   => 'deadbeef',
            version  => '0.0.1',
            ipaddr   => '127.0.0.1',
            ssh_port => '22',
            alias    => 'test relay',
        }
    )->status_is(204)->content_is('');

    my $report = path('t/integration/resource/passing-device-report.json')->slurp_utf8;
    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $report)->status_is(200)
        ->json_schema_is( 'ValidationState' );

    $t->get_ok('/device/TEST')
        ->status_is(200)
        ->json_schema_is('DetailedDevice')
        ->json_cmp_deeply({
            id => 'TEST',
            health => 'PASS',
            state => ignore,
            hostname => 'elfo',
            system_uuid => ignore,
            last_seen => ignore,
            do { my %X; %X{qw(asset_tag graduated latest_triton_reboot triton_setup triton_uuid uptime_since validated)} },
            created => ignore,
            updated => ignore,
            hardware_product => $hardware_product_id,
            location => undef,
            latest_report_is_invalid => JSON::PP::false,
            latest_report => superhashof({ product_name => 'Joyent-G1' }),
            invalid_report => undef,
            nics => supersetof(),
            disks => supersetof(superhashof({ serial_number => 'BTHC640405WM1P6PGN' })),
        });
};

subtest 'located device' => sub {
    # this autovivifies the device in the requested rack location
    $t->app->db_device_locations->assign_device_location('LOCATED_DEVICE', $rack_id, 1);

    $t->get_ok('/device/LOCATED_DEVICE')
        ->status_is(200)
        ->json_schema_is('DetailedDevice')
        ->json_cmp_deeply({
            id => 'LOCATED_DEVICE',
            health => 'UNKNOWN',
            state => 'UNKNOWN',
            do { my %X; %X{qw(asset_tag graduated hostname last_seen latest_triton_reboot system_uuid triton_setup triton_uuid uptime_since validated)} },
            created => ignore,
            updated => ignore,
            hardware_product => $hardware_product_id,
            location => {
                rack => {
                    id => $rack_id,
                    unit => 1,
                    name => 'rack 0a',
                    role => 'rack_role 42U',
                },
                datacenter => superhashof({ name => 'room-0a' }),
                target_hardware_product => superhashof({ 'alias' => 'Test Compute' }),
            },
            latest_report_is_invalid => JSON::PP::false,
            latest_report => undef,
            invalid_report => undef,
            nics => [],
            disks => [],
        });
};

subtest 'device network interfaces' => sub {
    $t->get_ok('/device/TEST/interface')
        ->status_is(200)
        ->json_schema_is('DeviceNics');

    $t->get_ok('/device/TEST/interface/ipmi1')
        ->status_is(200)
        ->json_schema_is('DeviceNic');

    $t->get_ok('/device/TEST/interface/ipmi1/mac')
        ->status_is(200)
        ->json_is({ mac => '18:66:da:78:d9:b3' });

    $t->get_ok('/device/TEST/interface/ipmi1/ipaddr')
        ->status_is(200)
        ->json_is({ ipaddr => '10.72.160.146' });
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
