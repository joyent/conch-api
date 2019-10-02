use strict;
use warnings;
use warnings FATAL => 'utf8';
use utf8;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More;
use Test::Warnings;
use Path::Tiny;
use Test::Deep;
use Test::Deep::JSON;
use Test::Conch;
use Mojo::JSON qw(from_json to_json);
use Conch::UUID 'create_uuid_str';
use List::Util 'first';

my $t = Test::Conch->new;

my $ro_user = $t->load_fixture('ro_user_global_workspace')->user_account;
$t->authenticate(email => $ro_user->email);

my $report = path('t/integration/resource/passing-device-report.json')->slurp_utf8;
my $hardware_product_compute;

subtest preliminaries => sub {
    my $report_data = from_json($report);

    $t->post_ok('/device/foo', json => $report_data)
        ->status_is(422)
        ->json_is({ error => 'Serial number provided to the API does not match the report data.' });

    $t->post_ok('/device/TEST', json => $report_data)
        ->status_is(409)
        ->json_is({ error => 'Could not locate hardware product for sku '.$report_data->{sku} });

    $t->post_ok('/device_report', json => $report_data)
        ->status_is(409)
        ->json_is({ error => 'Could not locate hardware product for sku '.$report_data->{sku} });

    $hardware_product_compute = first { $_->isa('Conch::DB::Result::HardwareProduct') }
        $t->load_fixture('hardware_product_compute');

    $t->post_ok('/device/TEST', json => $report_data)
        ->status_is(409)
        ->json_is({ error => 'Hardware product does not contain a profile' });

    $t->post_ok('/device_report', json => $report_data)
        ->status_is(409)
        ->json_is({ error => 'Hardware product does not contain a profile' });

    $t->load_fixture('hardware_product_profile_compute');

    $t->post_ok('/device/TEST', json => $report_data)
        ->status_is(409)
        ->json_is({ error => 'relay serial deadbeef is not registered' });

    $t->post_ok('/relay/deadbeef/register', json => { serial => 'deadbeef' })
        ->status_is(201);

    $t->post_ok('/device/TEST', json => $report_data)
        ->status_is(404)
        ->log_error_is('Failed to find device TEST');

    my $device = $t->generate_fixtures('device', {
        serial_number => 'TEST',
        hardware_product_id => $hardware_product_compute->id,
    });

    # deactivate product, create a new product with the same sku
    $hardware_product_compute->update({ deactivated => \'now()' });
    my $profile = $hardware_product_compute->hardware_product_profile;
    my $new_compute = $t->app->db_hardware_products->create(do { my %cols = $hardware_product_compute->get_columns; delete @cols{qw(id deactivated)}; \%cols });
    $profile->update({ hardware_product_id => $new_compute->id });

    $t->post_ok('/device/TEST', json => $report_data)
        ->status_is(409)
        ->json_is({ error => 'Report sku does not match expected hardware_product for device TEST' });

    $t->post_ok('/device_report', json => $report_data)
        ->status_is(409)
        ->json_is({ error => 'Report sku does not match expected hardware_product for device TEST' });

    $device->discard_changes;
    is($device->health, 'error', 'bad reports flip device health to error');

    # go back to the original hardware_product
    $new_compute->update({ deactivated => \'now()' });
    $hardware_product_compute->update({ deactivated => undef });
    $profile->update({ hardware_product_id => $hardware_product_compute->id });

    $t->post_ok('/device/TEST', json => $report_data)
        ->status_is(422)
        ->json_is({ error => 'failed to find validation plan' });

    $t->post_ok('/device_report', json => $report_data)
        ->status_is(422)
        ->json_is({ error => 'failed to find validation plan' });
};

# matches report's product_name = Joyent-G1
my $hardware_product = $t->load_fixture('hardware_product_compute');

# create a validation plan with all current validations in it
Conch::ValidationSystem->new(log => $t->app->log, schema => $t->app->schema)->load_validations;
my @validations = $t->app->db_validations->all;
my ($full_validation_plan) = $t->load_validation_plans([{
    name        => 'Conch v1 Legacy Plan: Server',
    description => 'Test Plan',
    validations => [ map $_->module, @validations ],
}]);

subtest 'run report without an existing device and without making updates' => sub {
    my $report_data = from_json($report);
    $report_data->{serial_number} = 'different_device';
    $report_data->{system_uuid} = create_uuid_str();

    $t->post_ok('/device_report', json => $report_data)
        ->status_is(200)
        ->json_schema_is('ReportValidationResults')
        ->json_cmp_deeply({
            device_serial_number => 'different_device',
            validation_plan_id => $full_validation_plan->id,
            status => any(qw(error fail pass)), # likely some validations will hate this report.
            # validations each produce one or more results
            results => array_each(any(map +{
                id => undef,
                validation_id => $_->id,
                category => $_->module->category,
                component => ignore,
                hardware_product_id => $hardware_product->id,
                hint => ignore,
                message => ignore,
                status => any(qw(error fail pass)),
            }, @validations)),
        });

    ok(!$t->app->db_devices->search({ serial_number => 'different_device' })->exists,
        'the device was not inserted into the database');
};

subtest 'save reports for device' => sub {
    # for these tests, we need to use a plan containing a validation we know will pass.
    # we move aside the plan containing all validations and replace it with a new one.
    $t->app->db_validation_plans->find($full_validation_plan->id)->update({ name => 'all validations' });

    $t->load_validation_plans([{
        name        => 'Conch v1 Legacy Plan: Server',
        description => 'Test Plan',
        validations => [ 'Conch::Validation::DeviceProductName' ],
    }]);

    # device reports are submitted thusly:
    # 0: pass
    # 1: pass (eventually deleted)
    # 2: pass (eventually deleted)
    # 3: invalid json (not saved)
    # 4: valid json, but does not pass the schema (not saved)
    # 5: pass
    # 6: validation error (empty product_name)
    # 7: pass

    my $good_report = path('t/integration/resource/passing-device-report.json')->slurp_utf8;
    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $good_report)
        ->status_is(200)
        ->location_is('/device/'.$t->tx->res->json->{device_id})
        ->json_schema_is('ValidationStateWithResults')
        ->json_cmp_deeply(superhashof({
            device_id => re(Conch::UUID::UUID_FORMAT),
            status => 'pass',
            completed => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            results => [
                superhashof({
                    status => 'pass',
                }),
            ],
        }));

    my $device_id = $t->tx->res->json->{device_id};
    my (@device_report_ids, @validation_state_ids);
    push @device_report_ids, $t->tx->res->json->{device_report_id};
    push @validation_state_ids, $t->tx->res->json->{id};

    my $device = $t->app->db_devices->find({ serial_number => 'TEST' });
    is($device->id, $device_id, 'got same device as was created on report submission');

    cmp_deeply(
        $device->self_rs->latest_device_report->single,
        methods(
            id => $device_report_ids[0],
            device_id => $device_id,
            report => json(from_json($good_report)),
            retain => bool(1),    # first report is always saved
        ),
        'stored the report in raw form',
    );

    $t->get_ok('/device_report/'.$device_report_ids[0])
        ->status_is(200)
        ->json_schema_is('DeviceReportRow')
        ->json_cmp_deeply({
            id => $device_report_ids[0],
            device_id => $device_id,
            report => from_json($good_report),
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        });

    is($device->related_resultset('device_reports')->count, 1, 'one device_report row created');
    is($device->related_resultset('validation_states')->count, 1, 'one validation_state row created');
    is($t->app->db_validation_results->count, 1, 'one validation result row created');
    is($device->related_resultset('device_relay_connections')->count, 1, 'one device_relay_connection row created');


    # submit another passing report, this time swapping around some iface_names...
    my $altered_report = from_json($good_report);
    ($altered_report->{interfaces}{eth5}{mac}, $altered_report->{interfaces}{eth1}{mac}) =
        ($altered_report->{interfaces}{eth1}{mac}, $altered_report->{interfaces}{eth5}{mac});

    $t->post_ok('/device/TEST', json => $altered_report)
        ->status_is(200)
        ->location_is('/device/'.$device_id)
        ->json_schema_is('ValidationStateWithResults')
        ->json_cmp_deeply(superhashof({
            device_id => $device_id,
            status => 'pass',
            completed => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        }));

    push @device_report_ids, $t->tx->res->json->{device_report_id};
    push @validation_state_ids, $t->tx->res->json->{id};

    is($device->related_resultset('device_reports')->count, 2, 'two device_report rows exist');
    is($device->related_resultset('validation_states')->count, 2, 'two validation_state rows exist');
    is($t->app->db_validation_results->count, 1, 'the second validation result is the same as the first');


    # submit another passing report (this makes 3)
    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $good_report)
        ->status_is(200)
        ->location_is('/device/'.$device_id)
        ->json_schema_is('ValidationStateWithResults')
        ->json_cmp_deeply(superhashof({
            device_id => $device_id,
            status => 'pass',
            completed => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        }));

    push @device_report_ids, $t->tx->res->json->{device_report_id};
    push @validation_state_ids, $t->tx->res->json->{id};

    # now the 2nd of the 3 reports should be deleted.
    is($device->related_resultset('device_reports')->count, 2, 'still just two device_report rows exist');
    is($device->related_resultset('validation_states')->count, 2, 'still just two validation_state rows exist');
    is($t->app->db_validation_results->count, 1, 'still just one validation result row exists');

    ok(!$t->app->db_device_reports->search({ id => $device_report_ids[1] })->exists,
        'second device_report deleted');
    ok(!$t->app->db_validation_states->search({ id => $validation_state_ids[1] })->exists,
        'second validation_state deleted');


    my $invalid_json_1 = '{"this": 1s n0t v@l,d ǰsøƞ'; # } for brace matching
    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json; charset=utf-8' },
            Encode::encode('UTF-8', $invalid_json_1))
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', [ { path => '/', message => re(qr/expected object/i) } ]);

    is($device->related_resultset('device_reports')->count, 2, 'still just two device_report rows exist');
    is($device->related_resultset('validation_states')->count, 2, 'still just two validation_state rows exist');
    is($t->app->db_validation_results->count, 1, 'still just one validation result row exists');

    $t->get_ok('/device/'.$device_id)
        ->status_is(200)
        ->json_schema_is('DetailedDevice')
        ->json_is('/health' => 'pass');

    my $invalid_json_2 = to_json({ foo => 'this 1s v@l,d ǰsøƞ, but violates the schema' });
    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json; charset=utf-8' },
            json => { foo => 'this 1s v@l,d ǰsøƞ, but violates the schema' })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', array_each(superhashof({ message => re(qr/missing property/i) })));

    is($device->related_resultset('device_reports')->count, 2, 'still just two device_report rows exist');
    is($device->related_resultset('validation_states')->count, 2, 'still just two validation_state rows exist');
    is($t->app->db_validation_results->count, 1, 'still just one validation result row exists');

    $t->get_ok('/device/TEST')
        ->status_is(200)
        ->json_schema_is('DetailedDevice')
        ->json_is('/health' => 'pass')
        ->json_is('/latest_report' => from_json($good_report));


    # submit another passing report...
    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $good_report)
        ->status_is(200)
        ->location_is('/device/'.$device_id)
        ->json_schema_is('ValidationStateWithResults')
        ->json_cmp_deeply(superhashof({
            device_id => $device_id,
            status => 'pass',
            completed => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        }));

    push @device_report_ids, $t->tx->res->json->{device_report_id};
    push @validation_state_ids, $t->tx->res->json->{id};

    ok(
        !$device->search_related('device_reports', { id => $device_report_ids[-2] })->exists,
        'the previous report was deleted, on receipt of another passing report',
    );

    is($device->related_resultset('device_reports')->count, 2, 'still just two device_report rows exist');
    is($device->related_resultset('validation_states')->count, 2, 'still just two rows exist');
    is($t->app->db_validation_results->count, 1, 'the latest validation result is the same as the first');


    my $error_report = path('t/integration/resource/error-device-report.json')->slurp_utf8;
    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $error_report)
        ->status_is(200)
        ->location_is('/device/'.$device_id)
        ->json_schema_is('ValidationStateWithResults')
        ->json_is('/status', 'error');

    push @device_report_ids, $t->tx->res->json->{device_report_id};
    push @validation_state_ids, $t->tx->res->json->{id};

    $t->get_ok('/device_report/'.$device_report_ids[-1])
        ->status_is(200)
        ->json_schema_is('DeviceReportRow')
        ->json_cmp_deeply({
            id => $device_report_ids[-1],
            device_id => $device_id,
            report => from_json($error_report),
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        });

    is($device->related_resultset('device_reports')->count, 3, 'now another device_report row exists');
    is($device->related_resultset('validation_states')->count, 3, 'now another validation_state row exists');
    is($t->app->db_validation_results->count, 2, 'now two validation results rows exist');

    $t->get_ok('/device/TEST')
        ->status_is(200)
        ->json_schema_is('DetailedDevice')
        ->json_is('/health' => 'error');


    # return device to a good state
    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $good_report)
        ->status_is(200)
        ->location_is('/device/'.$device_id)
        ->json_schema_is('ValidationStateWithResults')
        ->json_is('/status', 'pass');

    push @device_report_ids, $t->tx->res->json->{device_report_id};
    push @validation_state_ids, $t->tx->res->json->{id};

    is($device->related_resultset('device_reports')->count, 4, 'now another device_report row exists');
    is($device->related_resultset('validation_states')->count, 4, 'now another validation_state row exists');
    is($t->app->db_validation_results->count, 2, 'still just two validation result rows exist');


    cmp_deeply(
        [ $t->app->db_device_reports->order_by('created')->get_column('id')->all ],
        [ @device_report_ids[0,3,4,5] ],
        'kept all (parsable) device reports except the passing report with a pass on both sides',
    );

    cmp_deeply(
        [ $t->app->db_validation_states->order_by('created')->get_column('id')->all ],
        [ @validation_state_ids[0,3,4,5] ],
        'kept all validation_state records for every device_report we kept',
    );


    subtest 'relocate a disk' => sub {
        # move one of the device's disks to a different device (and change another field so it
        # needs to be updated)...
        my $report_data = from_json($good_report);
        my $disk_serial = (keys $report_data->{disks}->%*)[0];
        $report_data->{disks}{$disk_serial}{size} += 100;    # ugh! make report not-unique
        my $new_device = $t->app->db_devices->create({
            serial_number => 'ANOTHER_DEVICE',
            hardware_product_id => $device->hardware_product_id,
            health => 'unknown',
        });
        my $disk = $t->app->db_device_disks->search({ serial_number => $disk_serial })->single;
        $disk->update({ device_id => $new_device->id, vendor => 'King Zøg' });

        # then submit the report again and observe it moving back.
        $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, json => $report_data)
            ->status_is(200)
            ->location_is('/device/'.$device_id)
            ->json_schema_is('ValidationStateWithResults')
            ->json_is('/status', 'pass');

        $disk->discard_changes;
        is($disk->device_id, $device_id, 'an existing disk is relocated to the latest device reporting it');
    };

    subtest 'links' => sub {
        my $report_data = from_json($report);

        delete $report_data->@{qw(disks interfaces)};
        $report_data->{links} = [ 'https://foo.com/1' ];

        $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, json => $report_data)
            ->status_is(200)
            ->location_is('/device/'.$device_id)
            ->json_schema_is('ValidationStateWithResults')
            ->json_is('/status', 'pass');

        cmp_deeply(
            $t->app->db_devices->search({ serial_number => 'TEST' })->get_column('links')->single,
            [ 'https://foo.com/1' ],
            'single link is saved to the device',
        );

        push $report_data->{links}->@*, 'https://foo.com/0';
        $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, json => $report_data)
            ->status_is(200)
            ->location_is('/device/'.$device_id)
            ->json_schema_is('ValidationStateWithResults')
            ->json_is('/status', 'pass');

        cmp_deeply(
            $t->app->db_devices->search({ serial_number => 'TEST' })->get_column('links')->single,
            [ 'https://foo.com/0', 'https://foo.com/1' ],
            'new link is added to the device, without introducing duplicates; order is maintained',
        );
    };

    ok(
        $t->app->db_devices->search({ serial_number => 'TEST' })->devices_without_location->exists,
        'device is unlocated',
    );
};

subtest 'system_uuid collisions' => sub {
    my $report_data = from_json($report);
    $report_data->{serial_number} = 'i_was_here_first';

    my $existing_device = $t->app->db_devices->create({
        serial_number => 'i_was_here_first',
        hardware_product_id => $hardware_product_compute->id,
        health => 'unknown',
    });

    $t->post_ok('/device_report', json => $report_data)
        ->status_is(400)
        ->json_cmp_deeply({ error => re(qr/no validations ran: .*duplicate key value violates unique constraint "device_system_uuid_key"/) });

    $t->post_ok('/device/i_was_here_first', json => $report_data)
        ->status_is(400)
        ->json_cmp_deeply({ error => re(qr/could not process report for device i_was_here_first.*duplicate key value violates unique constraint "device_system_uuid_key"/) });

    $existing_device->discard_changes;
    is($existing_device->health, 'error', 'bad reports flip device health to error');
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
