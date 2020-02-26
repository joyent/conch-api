use v5.26;
use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Warnings;
use Path::Tiny;
use Test::Deep;
use Test::Conch;
use Mojo::JSON 'from_json';

my $t = Test::Conch->new;

my $ro_user = $t->load_fixture('ro_user_global_workspace')->user_account;
$t->authenticate(email => $ro_user->email);

my $validation = $t->load_validation('Conch::Validation::DeviceProductName');
my $validation_id = $validation->id;
my $test_validation_plan = $t->app->db_validation_plans->create({
    name => 'my_test_plan',
    description => 'another test plan',
    validation_plan_members => [ { validation => $validation } ],
});

my $good_report = path('t/integration/resource/passing-device-report.json')->slurp_utf8;
my $error_report = path('t/integration/resource/error-device-report.json')->slurp_utf8;
my $good_report_data = from_json($good_report);

my $hardware_product = $t->load_fixture('hardware_product_compute');
my ($server_validation_plan) = $t->load_validation_plans([{
    id => $hardware_product->validation_plan_id,
    description => 'Test Plan',
    validations => [ 'Conch::Validation::DeviceProductName' ],
}]);

$t->post_ok('/relay/deadbeef/register', json => { serial => 'deadbeef' })
    ->status_is(201);

# create the device and two reports
my $build = $t->generate_fixtures('build');
$build->create_related('user_build_roles', { user_id => $ro_user->id, role => 'admin' });
$t->post_ok('/build/'.$build->id.'/device', json => [ { serial_number => 'TEST', sku => $good_report_data->{sku} } ])
    ->status_is(204);

$t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $error_report)
    ->status_is(200)
    ->json_schema_is('ValidationStateWithResults')
    ->json_is('/status', 'error');
my $error_validation_state_id = $t->tx->res->json->{id};

$t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $good_report)
    ->status_is(200)
    ->json_schema_is('ValidationStateWithResults')
    ->json_is('/status', 'pass');
my $pass_validation_state_id = $t->tx->res->json->{id};

subtest 'test validating a device' => sub {
    $t->post_ok("/device/TEST/validation/$validation_id", json => {})
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', array_each(superhashof({ message => re(qr/missing property/i) })));

    $t->post_ok("/device/TEST/validation/$validation_id",
            { 'Content-Type' => 'application/json' }, $good_report)
        ->status_is(200)
        ->json_schema_is('ValidationResults')
        ->json_cmp_deeply([ superhashof({
            id => undef,
        }) ]);

    my $validation_results = $t->tx->res->json;

    $t->post_ok('/device/TEST/validation_plan/'.$test_validation_plan->id, json => {})
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', array_each(superhashof({ message => re(qr/missing property/i) })));

    $t->post_ok('/device/TEST/validation_plan/'.$test_validation_plan->id,
            { 'Content-Type' => 'application/json' }, $good_report)
        ->status_is(200)
        ->json_schema_is('ValidationResults')
        ->json_is($validation_results);
};


my $device = $t->app->db_devices->find({ serial_number => 'TEST' });
my @device_reports = $t->app->db_device_reports->rows(2)->order_by('created');

# manually create a failing validation result... ew ew ew.
# this uses the new validation plan, which is guaranteed to be different from the passing
# valdiation that got recorded for this device via the report earlier.
my (@fail_validation_state_id) = $t->app->db_validation_states->create({
    device_id => $device->id,
    validation_plan_id => $test_validation_plan->id,
    device_report_id => $device_reports[1]->id,
    status => 'fail',
    completed => \'now()',
    validation_state_members => [{
        result_order => 0,
        validation_result => {
            device_id => $device->id,
            hardware_product_id => $device->hardware_product_id,
            validation_id => $validation->id,
            message => 'faked failure',
            hint => 'boo',
            status => 'fail',
            category => 'test',
        },
    }],
})->id;

# record another, older, failing test using the same plan.
push @fail_validation_state_id, $t->app->db_validation_states->create({
    device_id => $device->id,
    validation_plan_id => $test_validation_plan->id,
    device_report_id => $device_reports[1]->id,
    status => 'fail',
    completed => '2001-01-01',
    validation_state_members => [{
        result_order => 0,
        validation_result => {
            created => '2001-01-01',
            device_id => $device->id,
            hardware_product_id => $device->hardware_product_id,
            validation_id => $validation->id,
            message => 'earlier failure',
            hint => 'boo',
            status => 'fail',
            category => 'test',
        },
    }],
})->id;

$t->get_ok('/device/TEST/validation_state')
    ->status_is(200)
    ->json_schema_is('ValidationStatesWithResults')
    ->json_cmp_deeply([
        {
            id => $pass_validation_state_id,
            validation_plan_id => $server_validation_plan->id,
            device_id => $device->id,
            device_report_id => $device_reports[1]->id,
            completed => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            status => 'pass',   # we force-validated this device earlier
            results => [ ignore ],
        },
        {
            id => $fail_validation_state_id[0],
            validation_plan_id => $test_validation_plan->id,
            device_id => $device->id,
            device_report_id => $device_reports[1]->id,
            completed => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            status => 'fail',
            results => [{
                id => re(Conch::UUID::UUID_FORMAT),
                hardware_product_id => $device->hardware_product_id,
                validation_id => $validation->id,
                component => undef,
                message => 'faked failure',
                hint => 'boo',
                status => 'fail',
                category => 'test',
            }],
        },
    ]);

my $validation_states = $t->tx->res->json;

$t->get_ok('/device/TEST/validation_state?status=pass')
    ->status_is(200)
    ->json_schema_is('ValidationStatesWithResults')
    ->json_is([ grep $_->{status} eq 'pass', $validation_states->@* ])
    ->json_is('/0/id', $pass_validation_state_id)
    ->json_is('/1', undef);

$t->get_ok('/device/TEST/validation_state?status=fail')
    ->status_is(200)
    ->json_schema_is('ValidationStatesWithResults')
    ->json_is([ grep $_->{status} eq 'fail', $validation_states->@* ])
    ->json_is('/0/id', $fail_validation_state_id[0])
    ->json_is('/1', undef);

$t->get_ok('/device/TEST/validation_state?status=error')
    ->status_is(200)
    ->json_schema_is('ValidationStatesWithResults')
    ->json_cmp_deeply([
        {
            id => $error_validation_state_id,
            validation_plan_id => $server_validation_plan->id,
            device_id => $device->id,
            device_report_id => $device_reports[0]->id,
            completed => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            status => 'error',
            results => [{
                id => re(Conch::UUID::UUID_FORMAT),
                hardware_product_id => $device->hardware_product_id,
                validation_id => re(Conch::UUID::UUID_FORMAT),
                component => undef,
                message => 'Missing \'product_name\' property',
                hint => ignore,
                status => 'error',
                category => 'IDENTITY',
            }],
        },
    ]);

$t->get_ok('/device/TEST/validation_state?status=pass&status=fail')
    ->status_is(200)
    ->json_schema_is('ValidationStatesWithResults')
    ->json_is($validation_states);

$t->get_ok('/device/TEST/validation_state?status=bar')
    ->status_is(400)
    ->json_schema_is('QueryParamsValidationError')
    ->json_cmp_deeply('/data' => { status => 'bar' })
    ->json_cmp_deeply('/details', [
        { path => '/status', message => re(qr/Not in enum list/) },
        { path => '/status', message => re(qr/Expected array - got string/) },
    ]);

$t->get_ok('/device/TEST/validation_state?status=pass&status=bar')
    ->status_is(400)
    ->json_schema_is('QueryParamsValidationError')
    ->json_cmp_deeply('/data' => { status => [ qw(pass bar) ] })
    ->json_cmp_deeply('/details', [
        { path => '/status', message => re(qr/Expected string - got array/) },
        { path => '/status/1', message => re(qr/Not in enum list/) },
    ]);

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
