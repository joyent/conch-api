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

my $ro_user = $t->load_fixture('ro_user');
$t->authenticate(email => $ro_user->email);

my $report = path('t/integration/resource/passing-device-report.json')->slurp_utf8;

# matches report's product_name = Joyent-G1 (compute)
my $hardware_product;

subtest preliminaries => sub {
    my $report_data = from_json($report);

    $t->post_ok('/device/TEST', json => $report_data)
        ->status_is(308)
        ->location_is('/device_report');

    $t->post_ok('/device_report?no_save_db=1', json => $report_data)
        ->status_is(409)
        ->json_is({ error => 'Could not find hardware product with sku '.$report_data->{sku} });

    $hardware_product = first { $_->isa('Conch::DB::Result::HardwareProduct') }
        $t->load_fixture('hardware_product_compute');

    $t->post_ok('/device_report', json => $report_data)
        ->status_is(409)
        ->json_is({ error => 'relay serial deadbeef is not registered' });

    my $null_user = $t->generate_fixtures('user_account');
    Test::Conch->new(pg => $t->pg)
        ->authenticate(email => $null_user->email)
        ->post_ok('/relay/deadbeef/register', json => { serial => 'deadbeef' })
        ->status_is(201);

    $t->post_ok('/device_report', json => $report_data)
        ->status_is(409)
        ->json_is({ error => 'relay serial deadbeef is not registered by user '.$ro_user->name });

    $t->post_ok('/relay/deadbeef/register', json => { serial => 'deadbeef' })
        ->status_is(204);

    $t->post_ok('/device_report', json => $report_data)
        ->status_is(404)
        ->log_warn_is('Could not find device TEST');
};

my $device = $t->generate_fixtures('device', {
    serial_number => 'TEST',
    hardware_product_id => $hardware_product->id,
});

# create a validation plan with all current validations in it
Conch::ValidationSystem->new(log => $t->app->log, schema => $t->app->schema)->load_validations;
my @validations = $t->app->db_validations->all;
my ($full_validation_plan) = $t->load_validation_plans([{
    id          => $hardware_product->validation_plan_id,
    name        => 'our validation plan',
    description => 'Test Plan',
    validations => [ map $_->module, @validations ],
}]);

subtest 'run report without an existing device and without making updates' => sub {
    my $report_data = from_json($report);
    $report_data->{serial_number} = 'different_device';
    $report_data->{system_uuid} = create_uuid_str();

    $t->txn_local('hardware_product must not be deactivated', sub {
        $hardware_product->update({ deactivated => \'now()' });

        $t->post_ok('/device_report?no_save_db=1', json => $report_data)
            ->status_is(409)
            ->json_is({ error => 'hardware_product (id '.$hardware_product->id.') is deactivated and cannot be used' });
    });

    $t->txn_local('validation_plan must not be deactivated', sub {
        $hardware_product->validation_plan->update({ deactivated => \'now()' });

        $t->post_ok('/device_report?no_save_db=1', json => $report_data)
            ->status_is(409)
            ->json_is({ error => 'validation_plan (id '.$hardware_product->validation_plan_id.') is deactivated and cannot be used' });
    });

    $t->post_ok('/device_report?no_save_db=1', json => $report_data)
        ->status_is(200)
        ->json_schema_is('ReportValidationResults')
        ->json_cmp_deeply({
            device_serial_number => 'different_device',
            hardware_product_id => $hardware_product->id,
            sku => $hardware_product->sku,
            status => any(qw(error fail pass)), # likely some validations will hate this report.
            # validations each produce one or more results
            results => array_each(any(map +{
                id => undef,
                validation_id => $_->id,
                category => $_->module->category,
                component => ignore,
                hint => ignore,
                message => ignore,
                status => any(qw(error fail pass)),
                do { my $v = $_; map +($_ => $v->$_), qw(name version description) },
            }, @validations)),
        });

    ok(!$t->app->db_devices->search({ serial_number => 'different_device' })->exists,
        'the device was not inserted into the database');
};

subtest 'save reports for device' => sub {
    # for these tests, we need to use a plan containing a validation we know will pass.
    # we remove all the existing validations from the plan and replace it with just one.
    $t->load_validation_plans([{
        id          => $hardware_product->validation_plan_id,
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

    $t->txn_local('hardware_product must not be deactivated', sub {
        $hardware_product->update({ deactivated => \'now()' });

        $t->post_ok('/device_report', { 'Content-Type' => 'application/json' }, $good_report)
            ->status_is(409)
            ->json_is({ error => 'hardware_product (id '.$hardware_product->id.') is deactivated and cannot be used' });
    });

    $t->post_ok('/device_report', { 'Content-Type' => 'application/json' }, $good_report)
        ->status_is(201)
        ->location_like(qr!^/validation_state/${\Conch::UUID::UUID_FORMAT}$!);

    $t->get_ok($t->tx->res->headers->location)
        ->status_is(200)
        ->json_schema_is('ValidationStateWithResults')
        ->json_cmp_deeply(superhashof({
            device_id => re(Conch::UUID::UUID_FORMAT),
            status => 'pass',
            results => array_each(
                superhashof({
                    status => 'pass',
                }),
            ),
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
    # DeviceProductName now creates two results in most cases
    is($t->app->db_validation_results->count, 2, 'two validation result rows created');
    is($device->related_resultset('device_relay_connections')->count, 1, 'one device_relay_connection row created');

    $t->txn_local('validation_plan must not be deactivated', sub {
        $hardware_product->validation_plan->update({ deactivated => \'now()' });

        $t->post_ok('/device_report', { 'Content-Type' => 'application/json' }, $good_report)
            ->status_is(409)
            ->json_is({ error => 'validation_plan (id '.$hardware_product->validation_plan_id.') is deactivated and cannot be used' });
    });

    # submit another passing report, this time swapping around some iface_names...
    my $altered_report = from_json($good_report);
    ($altered_report->{interfaces}{eth5}{mac}, $altered_report->{interfaces}{eth1}{mac}) =
        ($altered_report->{interfaces}{eth1}{mac}, $altered_report->{interfaces}{eth5}{mac});

    $t->post_ok('/device_report', json => $altered_report)
        ->status_is(201)
        ->location_like(qr!^/validation_state/${\Conch::UUID::UUID_FORMAT}$!);

    $t->get_ok($t->tx->res->headers->location)
        ->status_is(200)
        ->json_schema_is('ValidationStateWithResults')
        ->json_cmp_deeply(superhashof({
            device_id => $device_id,
            status => 'pass',
        }));

    push @device_report_ids, $t->tx->res->json->{device_report_id};
    push @validation_state_ids, $t->tx->res->json->{id};

    is($device->related_resultset('device_reports')->count, 2, 'two device_report rows exist');
    is($device->related_resultset('validation_states')->count, 2, 'two validation_state rows exist');
    is($t->app->db_validation_results->count, 2, 'the second two validation results are the same as the first two');


    # submit another passing report (this makes 3)
    $t->post_ok('/device_report', { 'Content-Type' => 'application/json' }, $good_report)
        ->status_is(201)
        ->location_like(qr!^/validation_state/${\Conch::UUID::UUID_FORMAT}$!);

    $t->get_ok($t->tx->res->headers->location)
        ->status_is(200)
        ->json_schema_is('ValidationStateWithResults')
        ->json_cmp_deeply(superhashof({
            device_id => $device_id,
            status => 'pass',
        }));

    push @device_report_ids, $t->tx->res->json->{device_report_id};
    push @validation_state_ids, $t->tx->res->json->{id};

    # now the 2nd of the 3 reports should be deleted.
    is($device->related_resultset('device_reports')->count, 2, 'still just two device_report rows exist');
    is($device->related_resultset('validation_states')->count, 2, 'still just two validation_state rows exist');
    is($t->app->db_validation_results->count, 2, 'still only two validation result rows exist');

    ok(!$t->app->db_device_reports->search({ id => $device_report_ids[1] })->exists,
        'second device_report deleted');
    ok(!$t->app->db_validation_states->search({ id => $validation_state_ids[1] })->exists,
        'second validation_state deleted');


    my $invalid_json_1 = '{"this": 1s n0t v@l,d ǰsøƞ'; # } for brace matching
    $t->post_ok('/device_report', { 'Content-Type' => 'application/json; charset=utf-8' },
            Encode::encode('UTF-8', $invalid_json_1))
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', [ superhashof({ error => 'wrong type (expected object)' }) ]);

    is($device->related_resultset('device_reports')->count, 2, 'still just two device_report rows exist');
    is($device->related_resultset('validation_states')->count, 2, 'still just two validation_state rows exist');
    is($t->app->db_validation_results->count, 2, 'still only two validation result rows exist');

    $t->get_ok('/device/'.$device_id)
        ->status_is(200)
        ->json_schema_is('DetailedDevice')
        ->json_is('/health' => 'pass');

    my $invalid_json_2 = to_json({ foo => 'this 1s v@l,d ǰsøƞ, but violates the schema' });
    $t->post_ok('/device_report', { 'Content-Type' => 'application/json; charset=utf-8' },
            json => { foo => 'this 1s v@l,d ǰsøƞ, but violates the schema' })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', [ superhashof({ error => 'missing properties: bios_version, product_name, sku, serial_number, system_uuid' }) ]);

    is($device->related_resultset('device_reports')->count, 2, 'still just two device_report rows exist');
    is($device->related_resultset('validation_states')->count, 2, 'still just two validation_state rows exist');
    is($t->app->db_validation_results->count, 2, 'still only two validation result rows exist');

    $t->get_ok('/device/TEST')
        ->status_is(200)
        ->json_schema_is('DetailedDevice')
        ->json_is('/health' => 'pass')
        ->json_is('/latest_report' => from_json($good_report));


    # submit another passing report...
    $t->post_ok('/device_report', { 'Content-Type' => 'application/json' }, $good_report)
        ->status_is(201)
        ->location_like(qr!^/validation_state/${\Conch::UUID::UUID_FORMAT}$!);

    $t->get_ok($t->tx->res->headers->location)
        ->status_is(200)
        ->json_schema_is('ValidationStateWithResults')
        ->json_cmp_deeply(superhashof({
            device_id => $device_id,
            status => 'pass',
        }));

    push @device_report_ids, $t->tx->res->json->{device_report_id};
    push @validation_state_ids, $t->tx->res->json->{id};

    ok(
        !$device->search_related('device_reports', { id => $device_report_ids[-2] })->exists,
        'the previous report was deleted, on receipt of another passing report',
    );

    is($device->related_resultset('device_reports')->count, 2, 'still just two device_report rows exist');
    is($device->related_resultset('validation_states')->count, 2, 'still just two rows exist');
    is($t->app->db_validation_results->count, 2, 'the second two validation results are the same as the first two');


    my $error_report = path('t/integration/resource/error-device-report.json')->slurp_utf8;
    $t->post_ok('/device_report', { 'Content-Type' => 'application/json' }, $error_report)
        ->status_is(201)
        ->location_like(qr!^/validation_state/${\Conch::UUID::UUID_FORMAT}$!);

    $t->get_ok($t->tx->res->headers->location)
        ->status_is(200)
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
    is($t->app->db_validation_results->count, 3, 'now three validation result rows exist');

    $t->get_ok('/device/TEST')
        ->status_is(200)
        ->json_schema_is('DetailedDevice')
        ->json_is('/health' => 'error');


    # return device to a good state
    $t->post_ok('/device_report', { 'Content-Type' => 'application/json' }, $good_report)
        ->status_is(201)
        ->location_like(qr!^/validation_state/${\Conch::UUID::UUID_FORMAT}$!);

    $t->get_ok($t->tx->res->headers->location)
        ->status_is(200)
        ->json_schema_is('ValidationStateWithResults')
        ->json_is('/status', 'pass');

    push @device_report_ids, $t->tx->res->json->{device_report_id};
    push @validation_state_ids, $t->tx->res->json->{id};

    is($device->related_resultset('device_reports')->count, 4, 'now another device_report row exists');
    is($device->related_resultset('validation_states')->count, 4, 'now another validation_state row exists');
    is($t->app->db_validation_results->count, 3, 'still just three validation result rows exist');


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
        $t->post_ok('/device_report', { 'Content-Type' => 'application/json' }, json => $report_data)
        ->status_is(201)
        ->location_like(qr!^/validation_state/${\Conch::UUID::UUID_FORMAT}$!);

    $t->get_ok($t->tx->res->headers->location)
            ->status_is(200)
            ->json_schema_is('ValidationStateWithResults')
            ->json_is('/status', 'pass');

        $disk->discard_changes;
        is($disk->device_id, $device_id, 'an existing disk is relocated to the latest device reporting it');
    };

    subtest 'links' => sub {
        my $report_data = from_json($report);

        delete $report_data->@{qw(disks interfaces)};
        $report_data->{links} = [ 'https://foo.com/1' ];

        $t->post_ok('/device_report', { 'Content-Type' => 'application/json' }, json => $report_data)
        ->status_is(201)
        ->location_like(qr!^/validation_state/${\Conch::UUID::UUID_FORMAT}$!);

    $t->get_ok($t->tx->res->headers->location)
            ->status_is(200)
            ->json_schema_is('ValidationStateWithResults')
            ->json_is('/status', 'pass');

        cmp_deeply(
            $t->app->db_devices->search({ serial_number => 'TEST' })->get_column('links')->single,
            [ 'https://foo.com/1' ],
            'single link is saved to the device',
        );

        push $report_data->{links}->@*, 'https://foo.com/0';
        $t->post_ok('/device_report', { 'Content-Type' => 'application/json' }, json => $report_data)
        ->status_is(201)
        ->location_like(qr!^/validation_state/${\Conch::UUID::UUID_FORMAT}$!);

    $t->get_ok($t->tx->res->headers->location)
            ->status_is(200)
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
        hardware_product_id => $hardware_product->id,
        health => 'unknown',
    });

    $t->post_ok('/device_report?no_save_db=1', json => $report_data)
        ->status_is(400)
        ->json_cmp_deeply({ error => re(qr/no validations ran: .*duplicate key value violates unique constraint "device_system_uuid_key"/) });

    $t->post_ok('/device_report', json => $report_data)
        ->status_is(400)
        ->json_cmp_deeply({ error => re(qr/^could not process report for device i_was_here_first.*duplicate key value violates unique constraint "device_system_uuid_key"/) });

    $existing_device->discard_changes;
    is($existing_device->health, 'error', 'bad reports flip device health to error');

    my $test_device = $t->app->db_devices->find({ serial_number => 'TEST' });
    is($test_device->health, 'error', 'TEST device had health set to error as well');
};

subtest 'submit report for decommissioned device' => sub {
    $t->app->db_devices->update_or_create({
        serial_number => 'DECOMMISSIONED_TEST',
        hardware_product_id => $t->load_fixture('hardware_product_compute')->id,
        health => 'pass',
        phase => 'decommissioned',
    });

    my $altered_report = from_json($report);
    $altered_report->{serial_number} = 'DECOMMISSIONED_TEST';

    $t->post_ok('/device_report', json => $altered_report)
        ->status_is(409)
        ->json_is({ error => 'device is decommissioned' });
};

subtest 'submit report for production device' => sub {
    my $new_device = $t->app->db_devices->create({
        serial_number => 'PRODUCTION_TEST',
        hardware_product_id => $hardware_product->id,
        health => 'unknown',
    });

    my $altered_report = from_json($report);
    $altered_report->{serial_number} = 'PRODUCTION_TEST';
    $altered_report->{system_uuid} = create_uuid_str();

    $t->post_ok('/device_report', json => $altered_report)
        ->status_is(201)
        ->location_like(qr!^/validation_state/${\Conch::UUID::UUID_FORMAT}$!);

    $t->get_ok($t->tx->res->headers->location)
        ->status_is(200)
        ->json_schema_is('ValidationStateWithResults')
        ->json_cmp_deeply(superhashof({
            device_id => re(Conch::UUID::UUID_FORMAT),
            status => ignore,
            results => ignore,
        }));

    my $device = $t->app->db_devices->find({ serial_number => 'PRODUCTION_TEST' });
    my @device_interfaces = $device->device_nics->active->order_by('mac')->hri->all;
    $device->update({ phase => 'production' });

    ($altered_report->{interfaces}{eth5}{mac}, $altered_report->{interfaces}{eth1}{mac}) =
        ($altered_report->{interfaces}{eth1}{mac}, $altered_report->{interfaces}{eth5}{mac});

    $t->post_ok('/device_report', json => $altered_report)
        ->status_is(201)
        ->location_like(qr!^/validation_state/${\Conch::UUID::UUID_FORMAT}$!);

    $t->get_ok($t->tx->res->headers->location)
        ->status_is(200)
        ->json_schema_is('ValidationStateWithResults')
        ->json_cmp_deeply(superhashof({
            device_id => $device->id,
            status => ignore,
            results => ignore,
        }));

    is($device->device_reports->count, 2, 'two reports were recorded for the device');

    cmp_deeply(
        [ $device->device_nics->active->order_by('mac')->hri->all ],
        \@device_interfaces,
        'device data was not updated in the database after moving its phase to production',
    );
};

subtest 'hardware_product is different' => sub {
    my $new_product = first { $_->isa('Conch::DB::Result::HardwareProduct') }
        $t->generate_fixtures('hardware_product', {
            sku => 'my_new_sku',
            generation_name => 'something',
            validation_plan_id => $full_validation_plan->id,
        });

    my $altered_report = from_json($report);
    $altered_report->{sku} = 'my_new_sku';
    $altered_report->{product_name} = 'something else';

    $t->post_ok('/device_report', json => $altered_report)
        ->status_is(201)
        ->location_like(qr!^/validation_state/${\Conch::UUID::UUID_FORMAT}$!);

    $t->get_ok($t->tx->res->headers->location)
        ->status_is(200)
        ->json_schema_is('ValidationStateWithResults')
        ->json_cmp_deeply(superhashof({
            device_id => $device->id,
            hardware_product_id => $hardware_product->id,   # this must NOT change
            status => ignore,
            results => array_each({
                id => ignore,
                validation_id => ignore,
                component => ignore,
                hint => ignore,
                message => ignore,
                status => 'fail',
                map +($_ => Conch::Validation::DeviceProductName->$_), qw(category name version description),
            }),
        }));

    $device->discard_changes;
    is(
        $device->hardware_product_id,
        $hardware_product->id,
        'device hardware_product was *not* updated to the hardware in the report',
    );
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
