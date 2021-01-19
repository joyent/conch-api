use v5.26;
use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Warnings;
use Path::Tiny;
use Test::Deep;
use Test::Conch;
use Mojo::JSON 'from_json';
use Conch::UUID;

my $t = Test::Conch->new;

my $ro_user = $t->load_fixture('ro_user');
$t->authenticate(email => $ro_user->email);

my $validation = $t->load_validation('Conch::Validation::DeviceProductName');
my $validation_id = $validation->id;
my $test_validation_plan = $t->app->db_legacy_validation_plans->create({
    name => 'my_test_plan',
    description => 'another test plan',
    legacy_validation_plan_members => [ { legacy_validation => $validation } ],
});

my $good_report = path('t/integration/resource/passing-device-report.json')->slurp_utf8;
my $error_report = path('t/integration/resource/error-device-report.json')->slurp_utf8;
my $good_report_data = from_json($good_report);

my $hardware_product = $t->load_fixture('hardware_product_compute');
my ($server_validation_plan) = $t->load_validation_plans([{
    id => $hardware_product->legacy_validation_plan_id,
    description => 'Test Plan',
    validations => [ 'Conch::Validation::DeviceProductName' ],
}]);

my @json_schemas = map $t->load_fixture($_), qw(json_schema_red json_schema_black);


$t->post_ok('/relay/deadbeef/register', json => { serial => 'deadbeef' })
    ->status_is(201);

# create the device and two reports
my $build = $t->generate_fixtures('build');
$build->create_related('user_build_roles', { user_id => $ro_user->id, role => 'admin' });
$t->post_ok('/build/'.$build->id.'/device', json => [ { serial_number => 'TEST', sku => $good_report_data->{sku} } ])
    ->status_is(204);

$t->post_ok('/device_report', { 'Content-Type' => 'application/json' }, $error_report)
    ->status_is(201)
    ->location_like(qr!^/validation_state/${\Conch::UUID::UUID_FORMAT}$!);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('ValidationStateWithResults')
    ->json_is('/status', 'error');
my $error_validation_state_id = $t->tx->res->json->{id};

# manually add some new-style error results to this validation state
$t->app->db_validation_state_members->create($_) foreach
  {
    validation_state_id => $error_validation_state_id,
    result_order => 0,
    validation_result => {
      json_schema_id => $json_schemas[0]->id,
      status => 'fail',
      data_location => '',
      schema_location => '/foo/$ref/bar',
      absolute_schema_location => '/json_schema/foo/bar',
      error => 'oh no not again',
    },
  },
  {
    validation_state_id => $error_validation_state_id,
    result_order => 1,
    validation_result => {
      json_schema_id => $json_schemas[0]->id,
      status => 'error',
      data_location => '',
      schema_location => '/$OMG',
      absolute_schema_location => '/$OMG',
      error => 'kaboom',
    },
  };


$t->post_ok('/device_report', { 'Content-Type' => 'application/json' }, $good_report)
    ->status_is(201)
    ->location_like(qr!^/validation_state/${\Conch::UUID::UUID_FORMAT}$!);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('ValidationStateWithResults')
    ->json_is('/status', 'pass');
my $pass_validation_state_id = $t->tx->res->json->{id};

subtest 'test validating a device' => sub {
    $t->post_ok("/device/TEST/validation/$validation_id", json => {})
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', [ superhashof({ error => 'missing properties: report_version, bios_version, product_name, sku, serial_number, system_uuid' }) ]);

    $t->post_ok("/device/TEST/validation/$validation_id",
            { 'Content-Type' => 'application/json' }, $good_report)
        ->status_is(200)
        ->json_schema_is('LegacyValidationResults')
        ->json_cmp_deeply(array_each(superhashof({
            id => undef,
        })));

    my $validation_results = $t->tx->res->json;

    $t->post_ok('/device/TEST/validation_plan/'.$test_validation_plan->id, json => {})
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', [ superhashof({ error => 'missing properties: report_version, bios_version, product_name, sku, serial_number, system_uuid' }) ]);

    $t->post_ok('/device/TEST/validation_plan/'.$test_validation_plan->id,
            { 'Content-Type' => 'application/json' }, $good_report)
        ->status_is(200)
        ->json_schema_is('LegacyValidationResults')
        ->json_is($validation_results);
};


my $device = $t->app->db_devices->find({ serial_number => 'TEST' });
my @device_reports = $t->app->db_device_reports->rows(2)->order_by('created');

$t->get_ok('/device/TEST/validation_state?status=fail')
    ->status_is(404)
    ->log_debug_is('No validation states for device');


# manually create some failing validation results... ew ew ew.
# this uses the new validation plan, which is guaranteed to be different from the passing
# valdiation that got recorded for this device via the report earlier.
my (@fail_validation_state_id) = $t->app->db_validation_states->create({
    device_id => $device->id,
    device_report_id => $device_reports[1]->id,
    hardware_product_id => $device->hardware_product_id,
    status => 'fail',
    legacy_validation_state_members => [
        {
            result_order => 0,
            legacy_validation_result => {
                device_id => $device->id,
                legacy_validation_id => $validation->id,
                message => 'faked failure',
                hint => 'boo',
                status => 'fail',
                category => 'test',
            },
        },
        {
            result_order => 1,
            legacy_validation_result => {
                device_id => $device->id,
                legacy_validation_id => $validation->id,
                message => 'faked success',
                hint => 'nope',
                status => 'pass',
                category => 'test',
            },
        },
    ],
    validation_state_members => [
      {
        result_order => 0,
        validation_result => {
          json_schema_id => $json_schemas[0]->id,
          status => 'pass',
          (map +($_ => undef), qw(data_location schema_location absolute_schema_location error)),
        },
      },
      {
        result_order => 1,
        validation_result => {
          json_schema_id => $json_schemas[0]->id,
          status => 'fail',
          data_location => '',
          schema_location => '/foo/$ref/bar',
          absolute_schema_location => '/json_schema/blah/bar',
          error => 'oh no',
        },
      },
      {
        result_order => 2,
        validation_result => {
          json_schema_id => $json_schemas[0]->id,
          status => 'fail',
          data_location => '',
          schema_location => '/foo/$ref/baz',
          absolute_schema_location => '/json_schema/blah/baz',
          error => 'oh no again',
        },
      },
      {
        result_order => 3,
        validation_result => {
          json_schema_id => $json_schemas[1]->id,
          status => 'pass',
          (map +($_ => undef), qw(data_location schema_location absolute_schema_location error)),
        },
      },
    ],
})->id;

# record another, older, failing test using the same plan.
push @fail_validation_state_id, $t->app->db_validation_states->create({
    device_id => $device->id,
    device_report_id => $device_reports[1]->id,
    hardware_product_id => $device->hardware_product_id,
    status => 'fail',
    created => '2001-01-01',
    legacy_validation_state_members => [{
        result_order => 0,
        legacy_validation_result => {
            created => '2001-01-01',
            device_id => $device->id,
            legacy_validation_id => $validation->id,
            message => 'earlier failure',
            hint => 'boo',
            status => 'fail',
            category => 'test',
        },
    }],
    validation_state_members => [{
      result_order => 0,
      validation_result => {
        json_schema_id => $json_schemas[0]->id,
        status => 'fail',
        data_location => '',
        schema_location => '/baz/$ref/qux',
        absolute_schema_location => '/json_schema/baz/bloop',
        error => 'oh no again',
      },
    }],
})->id;

$t->get_ok('/device/TEST/validation_state')
    ->status_is(200)
    ->json_schema_is('ValidationStateWithResults')
    ->json_cmp_deeply(
        {
            id => $fail_validation_state_id[0],
            hardware_product_id => $device->hardware_product_id,
            device_id => $device->id,
            device_report_id => $device_reports[1]->id,
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            status => 'fail',
            results => [
                {
                    id => re(Conch::UUID::UUID_FORMAT),
                    validation_id => $validation->id,
                    component => undef,
                    message => 'faked failure',
                    hint => 'boo',
                    status => 'fail',
                    category => 'test',
                    name => 'product_name',
                    version => 2,
                    description => 'Validate reported product name, sku matches product name, sku expected in rack layout',
                },
                {
                    id => re(Conch::UUID::UUID_FORMAT),
                    validation_id => $validation->id,
                    component => undef,
                    message => 'faked success',
                    hint => 'nope',
                    status => 'pass',
                    category => 'test',
                    name => 'product_name',
                    version => 2,
                    description => 'Validate reported product name, sku matches product name, sku expected in rack layout',
                },
                {
                  json_schema_id => $json_schemas[0]->id,
                  '$id' => '/json_schema/colour/red/1',
                  description => 'everything is red',
                  status => 'fail',
                  errors => [
                    {
                      data_location => '',
                      schema_location => '/foo/$ref/bar',
                      absolute_schema_location => '/json_schema/blah/bar',
                      error => 'oh no',
                    },
                    {
                      data_location => '',
                      schema_location => '/foo/$ref/baz',
                      absolute_schema_location => '/json_schema/blah/baz',
                      error => 'oh no again',
                    },
                  ],
                },
                {
                  json_schema_id => $json_schemas[1]->id,
                  '$id' => '/json_schema/colour/black/1',
                  description => 'everything is black',
                  status => 'pass',
                  errors => [],
                },
            ],
        },
    );

$t->get_ok('/device/TEST/validation_state?status=pass')
    ->status_is(200)
    ->json_schema_is('ValidationStateWithResults')
    ->json_is('/status', 'pass')
    ->json_is('/id', $pass_validation_state_id);

$t->get_ok('/device/TEST/validation_state?status=fail')
    ->status_is(200)
    ->json_schema_is('ValidationStateWithResults')
    ->json_is('/status', 'fail')
    ->json_is('/id', $fail_validation_state_id[0]);

$t->get_ok('/device/TEST/validation_state?status=error')
    ->status_is(200)
    ->json_schema_is('ValidationStateWithResults')
    ->json_cmp_deeply(
        {
            id => $error_validation_state_id,
            device_id => $device->id,
            device_report_id => $device_reports[0]->id,
            hardware_product_id => $device->hardware_product_id,
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            status => 'error',
            results => [
              {
                id => re(Conch::UUID::UUID_FORMAT),
                validation_id => re(Conch::UUID::UUID_FORMAT),
                component => undef,
                message => 'Missing \'product_name\' property',
                hint => ignore,
                status => 'error',
                category => 'IDENTITY',
                name => 'product_name',
                version => 2,
                description => 'Validate reported product name, sku matches product name, sku expected in rack layout',
              },
              {
                json_schema_id => $json_schemas[0]->id,
                '$id' => '/json_schema/colour/red/1',
                description => 'everything is red',
                status => 'error',
                errors => [
                  {
                    data_location => '',
                    schema_location => '/foo/$ref/bar',
                    absolute_schema_location => '/json_schema/foo/bar',
                    error => 'oh no not again',
                  },
                  {
                    data_location => '',
                    schema_location => '/$OMG',
                    absolute_schema_location => '/$OMG',
                    error => 'kaboom',
                  },
                ],
              },
            ],
        },
    );

$t->get_ok('/device/TEST/validation_state?status=pass&status=fail')
    ->status_is(200)
    ->json_schema_is('ValidationStateWithResults')
    ->json_is('/status', 'fail')
    ->json_is('/id', $fail_validation_state_id[0]);

$t->get_ok('/device/TEST/validation_state?status=bar')
    ->status_is(400)
    ->json_schema_is('QueryParamsValidationError')
    ->json_cmp_deeply('/data' => { status => 'bar' })
    ->json_cmp_deeply('/details', superbagof(
        superhashof({ data_location => '/status', error => 'value does not match' }),
    ));

$t->get_ok('/device/TEST/validation_state?status=pass&status=bar')
    ->status_is(400)
    ->json_schema_is('QueryParamsValidationError')
    ->json_cmp_deeply('/data' => { status => [ qw(pass bar) ] })
    ->json_cmp_deeply('/details', superbagof(
        superhashof({ data_location => '/status/1', error => 'value does not match' }),
    ));

done_testing;
# vim: set sts=2 sw=2 et :
