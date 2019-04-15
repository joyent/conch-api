use Mojo::Base -strict;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8
use warnings FATAL => 'utf8';
use Test::More;
use Data::UUID;
use Path::Tiny;
use Test::Deep;
use Test::Deep::JSON;
use Test::Warnings;
use Mojo::JSON qw(from_json to_json);
use Test::Conch;
use Storable 'dclone';

my $t = Test::Conch->new;
$t->load_fixture('legacy_datacenter');
$t->load_validation_plans([{
    name        => 'Conch v1 Legacy Plan: Server',
    description => 'Test Plan',
    validations => [ 'Conch::Validation::DeviceProductName' ],
}]);

my $uuid = Data::UUID->new;

$t->authenticate;

isa_ok($t->tx->res->cookie('conch'), 'Mojo::Cookie::Response');

$t->get_ok('/workspace')
    ->status_is(200)
    ->json_schema_is('WorkspacesAndRoles')
    ->json_is('/0/name', 'GLOBAL');

my $global_ws_id = $t->tx->res->json->[0]{id};
BAIL_OUT('No workspace ID') unless $global_ws_id;

$t->post_ok("/workspace/$global_ws_id/child",
        json => { name => 'test', description => 'also test' })
    ->status_is(201);

my $sub_ws_id = $t->tx->res->json->{id};
BAIL_OUT('Could not create sub-workspace.') unless $sub_ws_id;

subtest 'Device Report' => sub {
    # register the relay referenced by the report
    $t->post_ok('/relay/deadbeef/register',
            json => {
                serial   => 'deadbeef',
                version  => '0.0.1',
                ipaddr   => '127.0.0.1',
                ssh_port => 22,
                alias    => 'test relay'
            })
        ->status_is(204);

    # device reports are submitted thusly:
    # 0: pass
    # 1: pass (eventually deleted)
    # 2: pass
    # 3: - (invalid json)
    # 4: - (valid json, but does not pass the schema)
    # 5: pass
    # 6: error (empty product_name)
    # 7: pass

    my $good_report = path('t/integration/resource/passing-device-report.json')->slurp_utf8;
    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $good_report)
        ->status_is(200)
        ->json_schema_is('ValidationStateWithResults')
        ->json_cmp_deeply(superhashof({
            device_id => 'TEST',
            status => 'pass',
            completed => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            results => [
                superhashof({
                    device_id => 'TEST',
                    order => 0,
                    status => 'pass',
                }),
            ],
        }));

    my (@device_report_ids, @validation_state_ids);
    push @device_report_ids, $t->tx->res->json->{device_report_id};
    push @validation_state_ids, $t->tx->res->json->{id};

    my $device = $t->app->db_devices->find('TEST');
    cmp_deeply(
        $device->self_rs->latest_device_report->single,
        methods(
            id => $device_report_ids[0],
            device_id => 'TEST',
            report => json(from_json($good_report)),
            invalid_report => undef,
            retain => bool(1),    # first report is always saved
        ),
        'stored the report in raw form',
    );

    $t->get_ok('/device_report/'.$device_report_ids[0])
        ->status_is(200)
        ->json_schema_is('DeviceReportRow')
        ->json_cmp_deeply({
            id => $device_report_ids[0],
            device_id => 'TEST',
            report => from_json($good_report),
            invalid_report => undef,
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
        ->json_schema_is('ValidationStateWithResults')
        ->json_cmp_deeply(superhashof({
            device_id => 'TEST',
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
        ->json_schema_is('ValidationStateWithResults')
        ->json_cmp_deeply(superhashof({
            device_id => 'TEST',
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
        ->status_is(400);

    cmp_deeply(
        $device->self_rs->latest_device_report->single,
        methods(
            device_id => 'TEST',
            report => undef,
            invalid_report => $invalid_json_1,
        ),
        'stored the invalid report in raw form',
    );

    # the device report was saved, but no validations run.
    push @device_report_ids, $t->app->db_device_reports->order_by({ -desc => 'created' })->rows(1)->get_column('id')->single;

    $t->get_ok('/device_report/'.$device_report_ids[-1])
        ->status_is(200)
        ->json_schema_is('DeviceReportRow')
        ->json_cmp_deeply({
            id => $device_report_ids[-1],
            device_id => 'TEST',
            report => undef,
            invalid_report => $invalid_json_1,
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        });

    is($device->related_resultset('device_reports')->count, 3, 'now three device_report rows exist');
    is($device->related_resultset('validation_states')->count, 2, 'still just two validation_state rows exist');
    is($t->app->db_validation_results->count, 1, 'still just one validation result row exists');

    $t->get_ok('/device/TEST')
        ->status_is(200)
        ->json_schema_is('DetailedDevice')
        ->json_is('/health' => 'pass')
        ->json_is('/latest_report_is_invalid' => JSON::PP::true)
        ->json_is('/latest_report' => undef)
        ->json_is('/invalid_report' => $invalid_json_1);

    $t->get_ok('/device_report/'.$device_report_ids[0])
        ->status_is(200)
        ->json_schema_is('DeviceReportRow')
        ->json_cmp_deeply({
            id => $device_report_ids[0],
            device_id => 'TEST',
            report => from_json($good_report),
            invalid_report => undef,
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        });


    my $invalid_json_2 = to_json({ foo => 'this 1s v@l,d ǰsøƞ, but violates the schema' });
    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json; charset=utf-8' },
            json => { foo => 'this 1s v@l,d ǰsøƞ, but violates the schema' })
        ->status_is(400);

    cmp_deeply(
        $device->self_rs->latest_device_report->single,
        methods(
            device_id => 'TEST',
            invalid_report => $invalid_json_2,
        ),
        'stored the invalid report in raw form',
    );

    # the device report was saved, but no validations run.
    push @device_report_ids, $t->app->db_device_reports->order_by({ -desc => 'created' })->rows(1)->get_column('id')->single;

    $t->get_ok('/device_report/'.$device_report_ids[-1])
        ->status_is(200)
        ->json_schema_is('DeviceReportRow')
        ->json_cmp_deeply({
            id => $device_report_ids[-1],
            device_id => 'TEST',
            report => undef,
            invalid_report => to_json({ foo => 'this 1s v@l,d ǰsøƞ, but violates the schema' }),
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        });

    is($device->related_resultset('device_reports')->count, 4, 'now four device_report rows exist');
    is($device->related_resultset('validation_states')->count, 2, 'still just two validation_state rows exist');
    is($t->app->db_validation_results->count, 1, 'still just one validation result row exists');

    $t->get_ok('/device/TEST')
        ->status_is(200)
        ->json_schema_is('DetailedDevice')
        ->json_is('/health' => 'pass')
        ->json_is('/latest_report_is_invalid' => JSON::PP::true)
        ->json_is('/latest_report' => undef)
        ->json_is('/invalid_report' => $invalid_json_2);


    # submit another passing report...
    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $good_report)
        ->status_is(200)
        ->json_schema_is('ValidationStateWithResults')
        ->json_cmp_deeply(superhashof({
            device_id => 'TEST',
            status => 'pass',
            completed => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        }));

    push @device_report_ids, $t->tx->res->json->{device_report_id};
    push @validation_state_ids, $t->tx->res->json->{id};

    cmp_deeply(
        $device->self_rs->latest_device_report->single,
        methods(
            id => $device_report_ids[-1],
            device_id => 'TEST',
            report => json(from_json($good_report)),
            invalid_report => undef,
            retain => bool(1),    # we keep the first report after an error result
        ),
        'stored the report in raw form',
    );

    is($device->related_resultset('device_reports')->count, 5, 'now five device_report rows exist');
    is($device->related_resultset('validation_states')->count, 3, 'three validation_state rows exist');
    is($t->app->db_validation_results->count, 1, 'the latest validation result is the same as the first');


    my $error_report = path('t/integration/resource/error-device-report.json')->slurp_utf8;
    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $error_report)
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
            device_id => 'TEST',
            report => from_json($error_report),
            invalid_report => undef,
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        });

    is($device->related_resultset('device_reports')->count, 6, 'now six device_report rows exist');
    is($device->related_resultset('validation_states')->count, 4, 'now another validation_state row exists');
    is($t->app->db_validation_results->count, 2, 'now two validation results rows exist');

    $t->get_ok('/device/TEST')
        ->status_is(200)
        ->json_schema_is('DetailedDevice')
        ->json_is('/health' => 'error')
        ->json_is('/latest_report_is_invalid' => JSON::PP::false);


    # return device to a good state
    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $good_report)
        ->status_is(200)
        ->json_schema_is('ValidationStateWithResults')
        ->json_is('/status', 'pass');

    push @device_report_ids, $t->tx->res->json->{device_report_id};
    push @validation_state_ids, $t->tx->res->json->{id};

    is($device->related_resultset('device_reports')->count, 7, 'now seven device_report rows exist');
    is($device->related_resultset('validation_states')->count, 5, 'now four validation_state rows exist');
    is($t->app->db_validation_results->count, 2, 'still just two validation result rows exist');


    cmp_deeply(
        [ $t->app->db_device_reports->order_by('created')->get_column('id')->all ],
        [ @device_report_ids[0,2,3,4,5,6,7] ],
        'kept all device reports except the passing report with a pass on both sides',
    );

    cmp_deeply(
        [ $t->app->db_validation_states->order_by('created')->get_column('id')->all ],
        [ @validation_state_ids[0,2,-3,-2,-1] ],
        'not every device report had an associated validation_state record',
    );


    subtest 'relocate a disk' => sub {
        # move one of the device's disks to a different device (and change another field so it
        # needs to be updated)...
        my $report_data = from_json($good_report);
        my $disk_serial = (keys $report_data->{disks}->%*)[0];
        $report_data->{disks}{$disk_serial}{size} += 100;    # ugh! make report not-unique
        my $new_device = $t->app->db_devices->create({
            id => 'ANOTHER_DEVICE',
            hardware_product_id => $device->hardware_product_id,
            state => 'UNKNOWN',
            health => 'unknown',
        });
        my $disk = $t->app->db_device_disks->search({ serial_number => $disk_serial })->single;
        $disk->update({ device_id => $new_device->id, vendor => 'King Zøg' });

        # then submit the report again and observe it moving back.
        $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, json => $report_data)
            ->status_is(200)
            ->json_schema_is('ValidationStateWithResults')
            ->json_is('/status', 'pass');

        $disk->discard_changes;
        is($disk->device_id, $device->id, 'an existing disk is relocated to the latest device reporting it');
    };


    ok(
        $t->app->db_devices->search({ id => 'TEST' })->devices_without_location->exists,
        'device is unlocated',
    );
};

subtest 'Single device' => sub {
    my $rack_id = $t->load_fixture('legacy_rack')->id;

    # device settings that check for 'admin' permission need the device to have a location
    $t->post_ok("/workspace/$global_ws_id/rack/$rack_id/layout",
            json => { TEST => 1, NEW_DEVICE => 3 })
        ->status_is(200)
        ->json_schema_is('WorkspaceRackLayoutUpdateResponse')
        ->json_cmp_deeply({ updated => bag('TEST', 'NEW_DEVICE') });

    ok(
        !$t->app->db_devices->search({ id => 'TEST' })->devices_without_location->exists,
        'device is now located',
    );
};

subtest 'Validations' => sub {
    my $validation_id = $t->app->db_validations->get_column('id')->single;

    my $validation_plan = $t->app->db_validation_plans->create({
        name => 'my_test_plan',
        description => 'another test plan',
    });
    my $validation_plan_id = $validation_plan->id;
    $validation_plan->find_or_create_related('validation_plan_members', { validation_id => $validation_id });

    subtest 'test validating a device' => sub {
        my $good_report = path('t/integration/resource/passing-device-report.json')->slurp_utf8;

        $t->post_ok("/device/TEST/validation/$validation_id", json => {})
            ->status_is(400)
            ->json_schema_is('Error');

        $t->post_ok("/device/TEST/validation/$validation_id",
                { 'Content-Type' => 'application/json' }, $good_report)
            ->status_is(200)
            ->json_schema_is('ValidationResults')
            ->json_cmp_deeply([ superhashof({
                id => undef,
                device_id => 'TEST',
            }) ]);

        my $validation_results = $t->tx->res->json;

        $t->post_ok("/device/TEST/validation_plan/$validation_plan_id", json => {})
            ->status_is(400)
            ->json_schema_is('Error');

        $t->post_ok("/device/TEST/validation_plan/$validation_plan_id",
                { 'Content-Type' => 'application/json' }, $good_report)
            ->status_is(200)
            ->json_schema_is('ValidationResults')
            ->json_is($validation_results);
    };


    my $device = $t->app->db_devices->find('TEST');
    my $device_report = $t->app->db_device_reports->rows(1)->order_by({ -desc => 'created' })->single;
    my $validation = $t->load_validation('Conch::Validation::BiosFirmwareVersion');

    # manually create a failing validation result... ew ew ew.
    # this uses the new validation plan, which is guaranteed to be different from the passing
    # valdiation that got recorded for this device via the report earlier.
    my $validation_state = $t->app->db_validation_states->create({
        device_id => 'TEST',
        validation_plan_id => $validation_plan_id,
        device_report_id => $device_report->id,
        status => 'fail',
        completed => \'NOW()',
        validation_state_members => [{
            validation_result => {
                device_id => 'TEST',
                hardware_product_id => $device->hardware_product_id,
                validation_id => $validation->id,
                message => 'faked failure',
                hint => 'boo',
                status => 'fail',
                category => 'test',
                result_order => 0,
            },
        }],
    });

    # record another, older, failing test using the same plan.
    $t->app->db_validation_states->create({
        device_id => 'TEST',
        validation_plan_id => $validation_plan_id,
        device_report_id => $device_report->id,
        status => 'fail',
        completed => '2001-01-01',
        validation_state_members => [{
            validation_result => {
                created => '2001-01-01',
                device_id => 'TEST',
                hardware_product_id => $device->hardware_product_id,
                validation_id => $validation->id,
                message => 'earlier failure',
                hint => 'boo',
                status => 'fail',
                category => 'test',
                result_order => 0,
            },
        }],
    });

    $t->get_ok('/device/TEST/validation_state')
        ->status_is(200)
        ->json_schema_is('ValidationStatesWithResults')
        ->json_cmp_deeply(bag(
            {
                id => ignore,
                validation_plan_id => ignore,
                device_id => 'TEST',
                device_report_id => $device_report->id,
                completed => ignore,
                created => ignore,
                status => 'pass', # we force-validated this device earlier
                results => [ ignore ],
            },
            {
                id => $validation_state->id,
                validation_plan_id => $validation_plan_id,
                device_id => 'TEST',
                device_report_id => $device_report->id,
                completed => ignore,
                created => ignore,
                status => 'fail',
                results => [{
                    id => ignore,
                    device_id => 'TEST',
                    hardware_product_id => $device->hardware_product_id,
                    validation_id => $validation->id,
                    component_id => undef,
                    message => 'faked failure',
                    hint => 'boo',
                    status => 'fail',
                    category => 'test',
                    order => 0,
                }],
            },
        ));

    my $validation_states = $t->tx->res->json;

    $t->get_ok('/device/TEST/validation_state?status=pass')
        ->status_is(200)
        ->json_schema_is('ValidationStatesWithResults')
        ->json_is([ grep { $_->{status} eq 'pass' } $validation_states->@* ]);

    $t->get_ok('/device/TEST/validation_state?status=fail')
        ->status_is(200)
        ->json_schema_is('ValidationStatesWithResults')
        ->json_is([ grep { $_->{status} eq 'fail' } $validation_states->@* ]);

    $t->get_ok('/device/TEST/validation_state?status=error')
        ->status_is(200)
        ->json_schema_is('ValidationStatesWithResults')
        ->json_cmp_deeply([
            {
                id => ignore,
                validation_plan_id => ignore,
                device_id => 'TEST',
                device_report_id => ignore,
                completed => ignore,
                created => ignore,
                status => 'error',
                results => [{
                    id => ignore,
                    device_id => 'TEST',
                    hardware_product_id => $device->hardware_product_id,
                    validation_id => ignore,
                    component_id => undef,
                    message => 'Missing \'product_name\' property',
                    hint => ignore,
                    status => 'error',
                    category => 'BIOS',
                    order => 0,
                }],
            },
        ]);

    $t->get_ok('/device/TEST/validation_state?status=pass,fail')
        ->status_is(200)
        ->json_schema_is('ValidationStatesWithResults')
        ->json_is($validation_states);

    $t->get_ok('/device/TEST/validation_state?status=pass,bar')
        ->status_is(400)
        ->json_is({ error => "'status' query parameter must be any of 'pass', 'fail', or 'error'." });
};

subtest 'Device location' => sub {
    $t->post_ok('/device/TEST/location')
        ->status_is(400, 'requires body')
        ->json_like('/error', qr/Expected object/);

    my $rack_id = $t->load_fixture('legacy_rack')->id;

    $t->post_ok('/device/TEST/location', json => { rack_id => $rack_id, rack_unit => 42 })
        ->status_is(409)
        ->json_is({ error => "slot 42 does not exist in the layout for rack $rack_id" });

    $t->post_ok('/device/TEST/location', json => { rack_id => $rack_id, rack_unit => 3 })
        ->status_is(303)
        ->location_is('/device/TEST/location');

    $t->delete_ok('/device/TEST/location')
        ->status_is(204, 'can delete device location');

    $t->post_ok('/device/TEST/location', json => { rack_id => $rack_id, rack_unit => 3 })
        ->status_is(303, 'add it back');
};

subtest 'Log out' => sub {
    $t->post_ok('/logout')
        ->status_is(204);
    $t->get_ok('/workspace')
        ->status_is(401);
};

subtest 'Permissions' => sub {
    my $ro_name = 'wat';
    my $ro_email = 'readonly@wat.wat';
    my $ro_pass = 'password';

    my $rack_id = $t->load_fixture('legacy_rack')->id;

    subtest 'Read-only' => sub {
        my $ro_user = $t->app->db_user_accounts->create({
            name => $ro_name,
            email => $ro_email,
            password => $ro_pass,
            user_workspace_roles => [{
                workspace_id => $global_ws_id,
                role => 'ro',
            }],
        });

        $t->authenticate(user => $ro_email, password => $ro_pass);

        $t->get_ok('/workspace')
            ->status_is(200)
            ->json_schema_is('WorkspacesAndRoles')
            ->json_is('/0/name', 'GLOBAL');

        subtest "Can't create a subworkspace" => sub {
            $t->post_ok("/workspace/$global_ws_id/child",
                    json => { name => 'test', description => 'also test', })
                ->status_is(403)
                ->json_is({ error => 'Forbidden' });
        };

        subtest "Can't add a rack" => sub {
            $t->post_ok("/workspace/$global_ws_id/rack", json => { id => $rack_id })
                ->status_is(403)
                ->json_is({ error => 'Forbidden' });
        };

        subtest "Can't set a rack layout" => sub {
            $t->post_ok("/workspace/$global_ws_id/rack/$rack_id/layout", json => { TEST => 1 })
                ->status_is(403)
                ->json_is({ error => 'Forbidden' });
        };

        subtest "Can't add a user to workspace" => sub {
            $t->post_ok("/workspace/$global_ws_id/user",
                    json => { user => 'another@wat.wat', role => 'ro', })
                ->status_is(403)
                ->json_is({ error => 'Forbidden' });
        };

        subtest "Can't get a relay list" => sub {
            $t->get_ok('/relay')
                ->status_is(403);
        };

        $t->get_ok("/workspace/$global_ws_id/user")
            ->status_is(200, 'get list of users for this workspace')
            ->json_schema_is('WorkspaceUsers')
            ->json_cmp_deeply(bag(
                {
                    id => ignore,
                    name => $t->CONCH_USER,
                    email => $t->CONCH_EMAIL,
                    role => 'admin',
                },
                {
                    id => $ro_user->id,
                    name => $ro_name,
                    email => $ro_email,
                    role => 'ro',
                },
            ));

        subtest 'device settings' => sub {
            $t->post_ok('/device/TEST/settings', json => { name => 'new value' })
                ->status_is(403)
                ->json_is({ error => 'Forbidden' });
            $t->post_ok('/device/TEST/settings/foo', json => { foo => 'new_value' })
                ->status_is(403)
                ->json_is({ error => 'Forbidden' });
            $t->delete_ok('/device/TEST/settings/foo')
                ->status_is(403)
                ->json_is({ error => 'Forbidden' });
        };

        $t->post_ok('/logout')
            ->status_is(204);
    };

    subtest 'Read-write' => sub {
        my $name = 'integrator';
        my $email = 'integrator@wat.wat';
        my $pass = 'password';

        my $user = $t->app->db_user_accounts->create({
            name => $name,
            email => $email,
            password => $pass,
            user_workspace_roles => [{
                workspace_id => $global_ws_id,
                role => 'rw',
            }],
        });

        $t->authenticate(user => $email, password => $pass);

        $t->get_ok('/workspace')
            ->status_is(200)
            ->json_schema_is('WorkspacesAndRoles')
            ->json_is('/0/name', 'GLOBAL');

        subtest "Can't create a subworkspace" => sub {
            $t->post_ok("/workspace/$global_ws_id/child",
                    json => { name => 'test', description => 'also test', })
                ->status_is(403)
                ->json_is({ error => 'Forbidden' });
        };

        subtest "Can't add a user to workspace" => sub {
            $t->post_ok("/workspace/$global_ws_id/user",
                    json => { user => 'another@wat.wat', role => 'ro', })
                ->status_is(403)
                ->json_is({ error => 'Forbidden' });
        };

        subtest "Can't get a relay list" => sub {
            $t->get_ok('/relay')
                ->status_is(403);
        };

        $t->get_ok("/workspace/$global_ws_id/user")
            ->status_is(200, 'get list of users for this workspace')
            ->json_schema_is('WorkspaceUsers')
            ->json_cmp_deeply(bag(
                {
                    id => ignore,
                    name => $t->CONCH_USER,
                    email => $t->CONCH_EMAIL,
                    role => 'admin',
                },
                {
                    id => ignore,
                    name => $ro_name,
                    email => $ro_email,
                    role => 'ro',
                },
                {
                    id => $user->id,
                    name => $name,
                    email => $email,
                    role => 'rw',
                },
            ));

        subtest 'device settings' => sub {
            $t->post_ok('/device/TEST/settings', json => { key => 'value' })
                ->status_is(200, 'writing new key only requires rw');
            $t->post_ok('/device/TEST/settings/key', json => { key => 'new value' })
                ->status_is(403);
            $t->delete_ok('/device/TEST/settings/foo')
                ->status_is(403);

            $t->post_ok('/device/TEST/settings', json => { key => 'new value', 'tag.bar' => 'bar' })
                ->status_is(403);
            $t->post_ok('/device/TEST/settings', json => { 'tag.foo' => 'foo', 'tag.bar' => 'bar' })
                ->status_is(200);

            $t->post_ok('/device/TEST/settings/tag.bar', json => { 'tag.bar' => 'newbar' })
                ->status_is(200);
            $t->get_ok('/device/TEST/settings/tag.bar')
                ->status_is(200)
                ->json_is('/tag.bar', 'newbar', 'Setting was updated');
            $t->delete_ok('/device/TEST/settings/tag.bar')
                ->status_is(204)
                ->content_is('');
            $t->get_ok('/device/TEST/settings/tag.bar')
                ->status_is(404);
        };

        $t->post_ok('/logout')
            ->status_is(204);
    };
};

done_testing();
