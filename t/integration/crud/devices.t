use v5.26;
use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Warnings;
use Path::Tiny;
use Test::Deep;
use Test::Conch;
use Data::UUID;

my $t = Test::Conch->new;
$t->load_fixture_set('workspace_room_rack_layout', 0);

$t->load_validation_plans([{
    name        => 'Conch v1 Legacy Plan: Server',
    description => 'Test Plan',
    validations => [ 'Conch::Validation::DeviceProductName' ],
}]);

my $rack_id = $t->load_fixture('datacenter_rack_0a')->id;
my $hardware_product_id = $t->load_fixture('hardware_product_compute')->id;
my $user_workspace_role = $t->load_fixture('conch_user_global_workspace');

$t->authenticate;

$t->get_ok('/device/nonexistent')
    ->status_is(404)
    ->json_schema_is('Error')
    ->json_is({ error => 'Not found' });

subtest 'unlocated device' => sub {
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

    $t->get_ok('/device/TEST')
        ->status_is(200)
        ->json_schema_is('DetailedDevice')
        ->json_cmp_deeply({
            id => 'TEST',
            health => 'PASS',
            state => ignore,
            hostname => 'elfo',
            system_uuid => ignore,
            (map +($_ => undef), qw(asset_tag graduated latest_triton_reboot triton_setup triton_uuid uptime_since validated)),
            (map +($_ => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/)), qw(created updated last_seen)),
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
            (map +($_ => undef), qw(asset_tag graduated hostname last_seen latest_triton_reboot system_uuid triton_setup triton_uuid uptime_since validated)),
            (map +($_ => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/)), qw(created updated)),
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

    $t->txn_local('remove device from its workspace', sub ($t) {
        $t->app->db_workspace_datacenter_racks->delete;
        $t->app->db_workspace_datacenter_rooms->delete;
        $t->get_ok('/device/LOCATED_DEVICE')
            ->status_is(403)
            ->json_schema_is('Error')
            ->json_is('', { error => 'Forbidden' }, 'device isn\'t in a workspace anymore');
    });

    # TODO: permissions for PUT, DELETE queries

    subtest 'permissions for POST queries' => sub {
        my @queries = (
            '/device/LOCATED_DEVICE/graduate',
            '/device/LOCATED_DEVICE/triton_reboot',
            [ '/device/LOCATED_DEVICE/triton_uuid', json => { triton_uuid => Data::UUID->new->create_str } ],
            '/device/LOCATED_DEVICE/triton_setup',
            '/device/LOCATED_DEVICE/validated',
        );

        foreach my $query (@queries) {
            $t->post_ok(ref $query ? $query->@* : $query)
                ->status_is(303)
                ->location_is('/device/LOCATED_DEVICE');
        }

        $user_workspace_role->update({ role => 'ro' });

        foreach my $query (@queries) {
            $t->post_ok(ref $query ? $query->@* : $query)
                ->status_is(403)
                ->json_schema_is('Error')
                ->json_is({ error => 'Forbidden' });
        }
    };

    subtest 'permissions for GET queries' => sub {
        $t->app->db_devices->search({ id => 'LOCATED_DEVICE' })->update({
            hostname => 'Luci',
        });
        $t->app->db_device_settings->create({
            device_id => 'LOCATED_DEVICE',
            name => 'hello',
            value => 'world',
        });
        $t->app->db_device_nics->create({
            device_id => 'LOCATED_DEVICE',
            iface_name => 'home',
            iface_type => 'me',
            iface_vendor => 'me',
            mac => '00:00:00:00:00:00',
            ipaddr => '127.0.0.1',
        });

        my @queries = (
            '/device/LOCATED_DEVICE',
            '/device/LOCATED_DEVICE/location',
            '/device/LOCATED_DEVICE/settings',
            '/device/LOCATED_DEVICE/settings/hello',
            '/device/LOCATED_DEVICE/validation_state',
            '/device/LOCATED_DEVICE/interface',
            # TODO: filter search results for permissions
            #'/device?hostname=Luci',
            #'/device?mac=00:00:00:00:00:00',
            #'/device?ipaddr=127.0.0.1',
        );

        foreach my $query (@queries) {
            $t->get_ok($query)
                ->status_is(200);
        };

        $t->app->db_user_workspace_roles->delete;

        foreach my $query (@queries) {
            $t->get_ok($query)
                ->status_is(403)
                ->json_schema_is('Error')
                ->json_is({ error => 'Forbidden' });
        }
    };
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

$t->get_ok('/device/TEST')
    ->status_is(200)
    ->json_schema_is('DetailedDevice');

my $detailed_device = $t->tx->res->json;
my @macs = map $_->{mac}, $detailed_device->{nics}->@*;

my $undetailed_device = {
    $detailed_device->%*,
    ($t->app->db_device_locations->search({ device_id => 'TEST' })->hri->single // {})->%{qw(rack_id rack_unit_start)},
};
delete $undetailed_device->@{qw(latest_report_is_invalid latest_report invalid_report location nics disks)};

subtest 'get by device attributes' => sub {
    $t->get_ok('/device?hostname=elfo')
        ->status_is(200)
        ->json_schema_is('Devices')
        ->json_is('', [ $undetailed_device ], 'got device by hostname');

    $t->get_ok("/device?mac=$macs[0]")
        ->status_is(200)
        ->json_schema_is('Devices')
        ->json_is('', [ $undetailed_device ], 'got device by mac');

    # device_nics->[2] has ipaddr' => '172.17.0.173'.
    $t->get_ok('/device?ipaddr=172.17.0.173')
        ->status_is(200)
        ->json_schema_is('Devices')
        ->json_is('', [ $undetailed_device ], 'got device by ipaddr');
};

subtest 'mutate device attributes' => sub {
    $t->post_ok('/device/nonexistent/graduate')
        ->status_is(404)
        ->json_is({ error => 'Not found' });

    $t->post_ok('/device/TEST/graduate')
        ->status_is(303)
        ->location_is('/device/TEST');
    $detailed_device->{graduated} = re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/);

    $t->post_ok('/device/TEST/triton_setup')
        ->status_is(409)
        ->json_like('/error', qr/must be marked .+ before it can be .+ set up for Triton/);

    $t->post_ok('/device/TEST/triton_reboot')
        ->status_is(303)
        ->location_is('/device/TEST');
    $detailed_device->{latest_triton_reboot} = re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/);

    $t->post_ok('/device/TEST/triton_uuid')
        ->status_is(400, 'Request body required');

    $t->post_ok('/device/TEST/triton_uuid', json => { triton_uuid => 'not a UUID' })
        ->status_is(400)
        ->json_like('/error', qr/String does not match/);

    $t->post_ok('/device/TEST/triton_uuid', json => { triton_uuid => Data::UUID->new->create_str() })
        ->status_is(303)
        ->location_is('/device/TEST');
    $detailed_device->{triton_uuid} = re(Conch::UUID::UUID_FORMAT);

    $t->post_ok('/device/TEST/triton_setup')
        ->status_is(303)
        ->location_is('/device/TEST');
    $detailed_device->{triton_setup} = re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/);

    $t->post_ok('/device/TEST/asset_tag')
        ->status_is(400, 'Request body required');

    $t->post_ok('/device/TEST/asset_tag', json => { asset_tag => 'asset tag' })
        ->status_is(400)
        ->json_like('/error', qr/String does not match/);

    $t->post_ok('/device/TEST/asset_tag', json => { asset_tag => 'asset_tag' })
        ->status_is(303)
        ->location_is('/device/TEST');

    $t->post_ok('/device/TEST/asset_tag', json => { asset_tag => undef })
        ->status_is(303)
        ->location_is('/device/TEST');

    $t->post_ok('/device/TEST/validated')
        ->status_is(303)
        ->location_is('/device/TEST');
    $detailed_device->{validated} = re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/);

    $t->post_ok('/device/TEST/validated')
        ->status_is(204)
        ->content_is('');

    $t->get_ok('/device/TEST')
        ->status_is(200)
        ->json_schema_is('DetailedDevice')
        ->json_cmp_deeply({
            $detailed_device->%*,
            updated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        });
};

subtest 'Device settings' => sub {
    # device settings that check for 'admin' permission need the device to have a location
    my $user_workspace_role = $t->reload_fixture('conch_user_global_workspace');

    $t->app->db_device_settings->search({ device_id => 'LOCATED_DEVICE' })->delete;

    $t->get_ok('/device/LOCATED_DEVICE/settings')
        ->status_is(200)
        ->content_is('{}');

    $t->get_ok('/device/LOCATED_DEVICE/settings/foo')
        ->status_is(404)
        ->json_is({ error => 'No such setting \'foo\'' });

    $t->post_ok('/device/LOCATED_DEVICE/settings')
        ->status_is(400, 'Requires body')
        ->json_like('/error', qr/required/);

    $t->post_ok('/device/LOCATED_DEVICE/settings', json => { foo => 'bar' })
        ->status_is(200)
        ->content_is('');

    $t->get_ok('/device/LOCATED_DEVICE/settings')
        ->status_is(200)
        ->json_is('/foo', 'bar', 'Setting was stored');

    $t->get_ok('/device/LOCATED_DEVICE/settings/foo')
        ->status_is(200)
        ->json_is('/foo', 'bar', 'Setting was stored');

    $t->post_ok('/device/LOCATED_DEVICE/settings/fizzle', json => { no_match => 'gibbet' })
        ->status_is(400, 'Fail if parameter and key do not match');

    $t->post_ok('/device/LOCATED_DEVICE/settings/fizzle', json => { fizzle => 'gibbet' })
        ->status_is(200);

    $t->get_ok('/device/LOCATED_DEVICE/settings/fizzle')
        ->status_is(200)
        ->json_is('/fizzle', 'gibbet');

    $t->delete_ok('/device/LOCATED_DEVICE/settings/fizzle')
        ->status_is(204)
        ->content_is('');

    $t->get_ok('/device/LOCATED_DEVICE/settings/fizzle')
        ->status_is(404)
        ->json_is({ error => 'No such setting \'fizzle\'' });

    $t->delete_ok('/device/LOCATED_DEVICE/settings/fizzle')
        ->status_is(404)
        ->json_is({ error => 'No such setting \'fizzle\'' });

    $t->post_ok('/device/LOCATED_DEVICE/settings', json => { 'tag.foo' => 'foo', 'tag.bar' => 'bar' })
        ->status_is(200);

    $t->post_ok('/device/LOCATED_DEVICE/settings/tag.bar', json => { 'tag.bar' => 'newbar' })
        ->status_is(200);

    $t->get_ok('/device/LOCATED_DEVICE/settings/tag.bar')
        ->status_is(200)
        ->json_is('/tag.bar', 'newbar', 'Setting was updated');

    $t->delete_ok('/device/LOCATED_DEVICE/settings/tag.bar')
        ->status_is(204)
        ->content_is('');

    $t->get_ok('/device/LOCATED_DEVICE/settings/tag.bar')
        ->status_is(404)
        ->json_is({ error => 'No such setting \'tag.bar\'' });

    $t->get_ok('/device/LOCATED_DEVICE')
        ->status_is(200)
        ->json_schema_is('DetailedDevice');

    my $detailed_device = $t->tx->res->json;

    my $undetailed_device = {
        $detailed_device->%*,
        ($t->app->db_device_locations->search({ device_id => 'LOCATED_DEVICE' })->hri->single // {})->%{qw(rack_id rack_unit_start)},
    };
    delete $undetailed_device->@{qw(latest_report_is_invalid latest_report invalid_report location nics disks)};

    $t->get_ok('/device?foo=bar')
        ->status_is(200)
        ->json_schema_is('Devices')
        ->json_is('', [ $undetailed_device ], 'got device by arbitrary setting key');
};

subtest 'Device PXE' => sub {
    my $layout = $t->load_fixture('datacenter_rack_0a_layout_3_6');

    my $device_pxe = $t->app->db_devices->create({
        id => 'PXE_TEST',
        hardware_product_id => $layout->hardware_product_id,
        state => 'UNKNOWN',
        health => 'UNKNOWN',
        device_relay_connections => [ {
            relay => {
                id => 'relay_id',
                user_relay_connections => [ { user_id => $t->load_fixture('conch_user')->id } ],
            }
        } ],
        device_nics => [
            {
                state => 'up',
                iface_name => 'milhouse',
                iface_type => 'human',
                iface_vendor => 'Groening',
                mac => '00:00:00:00:00:aa',
                ipaddr => '0.0.0.1',
            },
            {
                state => 'up',
                iface_name => 'ned',
                iface_type => 'human',
                iface_vendor => 'Groening',
                mac => '00:00:00:00:00:bb',
                ipaddr => '0.0.0.2',
            },
            {
                state => undef,
                iface_name => 'ipmi1',
                iface_type => 'human',
                iface_vendor => 'Groening',
                mac => '00:00:00:00:00:cc',
                ipaddr => '0.0.0.3',
            },
        ],
    });

    $t->get_ok('/device/PXE_TEST/pxe')
        ->status_is(200)
        ->json_schema_is('DevicePXE')
        ->json_is({
            id => 'PXE_TEST',
            location => undef,
            ipmi => {
                mac => '00:00:00:00:00:cc',
                ip => '0.0.0.3',
            },
            pxe => {
                mac => '00:00:00:00:00:aa',
            },
        });

    $layout->create_related('device_location', { device_id => 'PXE_TEST' });
    my $datacenter = $t->load_fixture('datacenter_0');

    $t->get_ok('/device/PXE_TEST/pxe')
        ->status_is(200)
        ->json_schema_is('DevicePXE')
        ->json_is({
            id => 'PXE_TEST',
            location => {
                datacenter => {
                    name => $datacenter->region,
                    vendor_name => $datacenter->vendor_name,
                },
                rack => {
                    name => $layout->datacenter_rack->name,
                    rack_unit_start => $layout->rack_unit_start,
                },
            },
            ipmi => {
                mac => '00:00:00:00:00:cc',
                ip => '0.0.0.3',
            },
            pxe => {
                mac => '00:00:00:00:00:aa',
            },
        });


    $device_pxe->delete_related('device_location');
    $device_pxe->delete_related('device_nics');

    $t->get_ok('/device/PXE_TEST/pxe')
        ->status_is(200)
        ->json_schema_is('DevicePXE')
        ->json_is({
            id => 'PXE_TEST',
            location => undef,
            ipmi => undef,
            pxe => undef,
        });
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
