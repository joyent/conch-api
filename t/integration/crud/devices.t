use v5.26;
use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Warnings;
use Path::Tiny;
use Test::Deep;
use Test::Conch;
use Data::UUID;
use Mojo::JSON 'from_json';

my $t = Test::Conch->new;
$t->load_fixture_set('workspace_room_rack_layout', 0);

$t->load_validation_plans([{
    name        => 'Conch v1 Legacy Plan: Server',
    description => 'Test Plan',
    validations => [ 'Conch::Validation::DeviceProductName' ],
}]);

my $rack = $t->load_fixture('rack_0a');
my $rack_id = $rack->id;
my $hardware_product_id = $t->load_fixture('hardware_product_compute')->id;

# perform most tests as a user with read only access to the GLOBAL workspace
my $null_user = $t->load_fixture('null_user');
my $ro_user = $t->load_fixture('ro_user_global_workspace')->user_account;
my $admin_user = $t->load_fixture('conch_user_global_workspace')->user_account;
$t->authenticate(user => $ro_user->email);

$t->get_ok('/device/nonexistent')
    ->status_is(404);


subtest 'unlocated device, no registered relay' => sub {
    my $report_data = from_json(path('t/integration/resource/passing-device-report.json')->slurp_utf8);
    $t->post_ok('/device/TEST', json => $report_data)
        ->status_is(400)
        ->json_schema_is('Error')
        ->json_is({ error => 'relay serial deadbeef is not registered' });

    delete $report_data->{relay};

    $t->post_ok('/device/TEST', json => $report_data)
        ->status_is(200)
        ->json_schema_is('ValidationStateWithResults');

    my $device_report_id = $t->tx->res->json->{device_report_id};

    $t->get_ok('/device/TEST')
        ->status_is(403)
        ->json_schema_is('Error')
        ->json_is('', { error => 'Forbidden' }, 'unlocated device isn\'t visible to a ro user');

    $t->get_ok('/device_report/'.$device_report_id)
        ->status_is(403)
        ->json_schema_is('Error')
        ->json_is('', { error => 'Forbidden' }, 'unlocated device report isn\'t visible to a ro user');

    {
        $t->authenticate(user => $admin_user->email);

        $t->get_ok('/device/TEST')
            ->status_is(200)
            ->json_schema_is('DetailedDevice', 'devices are always visible to a sysadmin user');

        $t->get_ok('/device_report/'.$device_report_id)
            ->status_is(200)
            ->json_schema_is('DeviceReportRow', 'device reports are always visible to a sysadmin user');

        $t->authenticate(user => $ro_user->email);
    }
};

subtest 'unlocated device with a registered relay' => sub {
    $t->post_ok('/relay/deadbeef/register', json => { serial => 'deadbeef' })
        ->status_is(204)
        ->content_is('');

    my $report = path('t/integration/resource/passing-device-report.json')->slurp_utf8;
    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $report)
        ->status_is(200)
        ->json_schema_is('ValidationStateWithResults');

    my $validation_state = $t->tx->res->json;

    $t->get_ok('/device_report/'.$validation_state->{device_report_id})
        ->status_is(200)
        ->json_schema_is('DeviceReportRow')
        ->json_cmp_deeply({
            id => $validation_state->{device_report_id},
            device_id => 'TEST',
            report => from_json($report),
            invalid_report => undef,
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        });

    $t->get_ok('/device/TEST')
        ->status_is(200)
        ->json_schema_is('DetailedDevice')
        ->json_cmp_deeply({
            id => 'TEST',
            health => 'pass',
            state => ignore,
            hostname => 'elfo',
            system_uuid => ignore,
            phase => 'integration',
            (map +($_ => undef), qw(asset_tag graduated latest_triton_reboot triton_setup triton_uuid uptime_since validated)),
            (map +($_ => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/)), qw(created updated last_seen)),
            hardware_product => $hardware_product_id,
            location => undef,
            latest_report_is_invalid => JSON::PP::false,
            latest_report => from_json($report),
            invalid_report => undef,
            nics => supersetof(),
            disks => supersetof(superhashof({ serial_number => 'BTHC640405WM1P6PGN' })),
        });

    $t->app->db_device_disks->deactivate;
    $t->get_ok('/device/TEST')
        ->status_is(200)
        ->json_schema_is('DetailedDevice')
        ->json_cmp_deeply({
            id => 'TEST',
            health => 'pass',
            state => ignore,
            hostname => 'elfo',
            system_uuid => ignore,
            phase => 'integration',
            (map +($_ => undef), qw(asset_tag graduated latest_triton_reboot triton_setup triton_uuid uptime_since validated)),
            (map +($_ => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/)), qw(created updated last_seen)),
            hardware_product => $hardware_product_id,
            location => undef,
            latest_report_is_invalid => JSON::PP::false,
            latest_report => superhashof({ product_name => 'Joyent-G1' }),
            invalid_report => undef,
            nics => supersetof(),
            disks => [],
        });

    $t->get_ok('/validation_state/'.$validation_state->{id})
        ->status_is(200)
        ->json_schema_is('ValidationStateWithResults')
        ->json_is($validation_state);

    $t->authenticate(user => $null_user->email);
    $t->get_ok('/device/TEST')
        ->status_is(403)
        ->json_schema_is('Error')
        ->json_is('', { error => 'Forbidden' }, 'cannot see device without the relay connection');

    $t->get_ok('/device_report/'.$validation_state->{device_report_id})
        ->status_is(403)
        ->json_schema_is('Error')
        ->json_is('', { error => 'Forbidden' }, 'cannot see device report without the relay connection');

    {
        $null_user->update({ is_admin => 1 });

        $t->get_ok('/device/TEST')
            ->status_is(200)
            ->json_schema_is('DetailedDevice', 'devices are always visible to a sysadmin user');

        $t->get_ok('/device_report/'.$validation_state->{device_report_id})
            ->status_is(200)
            ->json_schema_is('DeviceReportRow', 'device reports are always visible to a sysadmin user');

        $null_user->update({ is_admin => 0 });

        $t->authenticate(user => $ro_user->email);
    }
};

subtest 'located device' => sub {
    # this autovivifies the device in the requested rack location
    $t->app->db_device_locations->assign_device_location('LOCATED_DEVICE', $rack_id, 1);

    $t->get_ok('/device/LOCATED_DEVICE')
        ->status_is(200)
        ->json_schema_is('DetailedDevice')
        ->json_cmp_deeply({
            id => 'LOCATED_DEVICE',
            health => 'unknown',
            state => 'UNKNOWN',
            phase => 'integration',
            (map +($_ => undef), qw(asset_tag graduated hostname last_seen latest_triton_reboot system_uuid triton_setup triton_uuid uptime_since validated)),
            (map +($_ => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/)), qw(created updated)),
            hardware_product => $hardware_product_id,
            location => {
                rack => {
                    (map +($_ => $rack->$_), qw(id name datacenter_room_id serial_number asset_tag phase)),
                    role => $rack->rack_role_id,
                    (map +($_ => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/)), qw(created updated)),
                },
                rack_unit_start => 1,
                datacenter => ignore,
                datacenter_room => superhashof({ az => 'room-0a' }),
                target_hardware_product => superhashof({ alias => 'Test Compute' }),
            },
            latest_report_is_invalid => JSON::PP::false,
            latest_report => undef,
            invalid_report => undef,
            nics => [],
            disks => [],
        });

    $t->txn_local('remove device from its workspace', sub ($t) {
        $t->app->db_workspace_racks->delete;
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
            [ '/device/LOCATED_DEVICE/phase', json => { phase => 'decommissioned' } ],
        );

        $t->authenticate(user => $t->load_fixture('rw_user_global_workspace')->user_account->email);

        foreach my $query (@queries) {
            $t->post_ok(ref $query ? $query->@* : $query)
                ->status_is(303)
                ->location_is('/device/LOCATED_DEVICE');
        }

        # now switch back to ro_user...
        $t->authenticate(user => $ro_user->email);
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
            '/device/LOCATED_DEVICE/phase',
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

        $ro_user->update({ is_admin => 1 });
        foreach my $query (@queries) {
            $t->get_ok($query)
                ->status_is(200);
        }
        $ro_user->update({ is_admin => 0 });
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

$t->app->db_device_nics->create({
    mac => '00:00:00:00:00:0'.$_,
    device_id => 'TEST',
    iface_name => $_,
    iface_type => 'foo',
    iface_vendor => 'bar',
    iface_driver => 'baz',
    deactivated => \'now()',
}) foreach (7..9);

$t->get_ok('/device/TEST')
    ->status_is(200)
    ->json_schema_is('DetailedDevice')
    ->json_is($detailed_device);

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
        ->status_is(404);

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

    $t->post_ok('/device/TEST/phase', json => { phase => 'decommissioned' })
        ->status_is(303)
        ->location_is('/device/TEST');
    $detailed_device->{phase} = 'decommissioned';

    $t->get_ok('/device/TEST/phase')
        ->status_is(200)
        ->json_schema_is('DevicePhase')
        ->json_is({ id => 'TEST', phase => 'decommissioned' });

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
    $t->authenticate(user => $user_workspace_role->user_account->email);

    $t->app->db_device_settings->search({ device_id => 'LOCATED_DEVICE' })->delete;

    $t->get_ok('/device/LOCATED_DEVICE/settings')
        ->status_is(200)
        ->content_is('{}');

    $t->get_ok('/device/LOCATED_DEVICE/settings/foo')
        ->status_is(404);

    $t->post_ok('/device/LOCATED_DEVICE/settings')
        ->status_is(400, 'Requires body');

    $t->post_ok('/device/LOCATED_DEVICE/settings/FOO/BAR', json => { 'FOO/BAR' => 1 })
        ->status_is(404);

    $t->post_ok('/device/LOCATED_DEVICE/settings', json => { foo => 'bar' })
        ->status_is(200)
        ->content_is('');

    $t->get_ok('/device/LOCATED_DEVICE/settings')
        ->status_is(200)
        ->json_is('/foo', 'bar', 'Setting was stored');

    $t->get_ok('/device/LOCATED_DEVICE/settings/foo')
        ->status_is(200)
        ->json_is('/foo', 'bar', 'Setting was stored');

    $t->post_ok('/device/LOCATED_DEVICE/settings/foo', json => { foo => { bar => 'baz' } })
        ->status_is(400)
        ->json_cmp_deeply({ error => re(qr/foo: /) });  # validation failure

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
        ->status_is(404);

    $t->delete_ok('/device/LOCATED_DEVICE/settings/fizzle')
        ->status_is(404);

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
        ->status_is(404);

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
    my $layout = $t->load_fixture('rack_0a_layout_3_6');

    my $device_pxe = $t->app->db_devices->create({
        id => 'PXE_TEST',
        hardware_product_id => $layout->hardware_product_id,
        state => 'UNKNOWN',
        health => 'unknown',
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
                    name => $layout->rack->name,
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
