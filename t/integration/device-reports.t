use v5.26;
use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Warnings;
use Path::Tiny;
use Test::Deep;
use Test::Conch;

my $t = Test::Conch->new;

my $ro_user = $t->load_fixture('ro_user_global_workspace')->user_account;
$t->authenticate(user => $ro_user->email);

my $report = path('t/integration/resource/passing-device-report.json')->slurp_utf8;

subtest preliminaries => sub {
    $t->post_ok('/device/foo', { 'Content-Type' => 'application/json' }, $report)
        ->status_is(422)
        ->json_is({ error => 'Serial number provided to the API does not match the report data.' });

    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $report)
        ->status_is(409)
        ->json_is({ error => 'Could not locate hardware product' });

    $t->load_fixture('hardware_product_compute');

    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $report)
        ->status_is(409)
        ->json_is({ error => 'Hardware product does not contain a profile' });

    $t->load_fixture('hardware_product_profile_compute');

    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $report)
        ->status_is(400)
        ->json_is({ error => 'relay serial deadbeef is not registered' });

    $t->post_ok('/relay/deadbeef/register', json => { serial => 'deadbeef' })
        ->status_is(204);

    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $report)
        ->status_is(422)
        ->json_is({ error => 'failed to find validation plan' });
};

# matches report's product_name = Joyent-G1
my $hardware_product = $t->load_fixture('hardware_product_compute');

# create a validation plan with all current validations in it
Conch::ValidationSystem->new(log => $t->app->log, schema => $t->app->schema)->load_validations;
my @validations = $t->app->db_validations->all;
my ($validation_plan) = $t->load_validation_plans([{
    name        => 'Conch v1 Legacy Plan: Server',
    description => 'Test Plan',
    validations => [ map $_->module, @validations ],
}]);

subtest 'run report without an existing device' => sub {
    $t->post_ok('/device_report', { 'Content-Type' => 'application/json' }, $report)
        ->status_is(200)
        ->json_schema_is('ReportValidationResults')
        ->json_cmp_deeply({
            device_id => 'TEST',
            validation_plan_id => $validation_plan->id,
            status => any(qw(error fail pass)), # likely some validations will hate this report.
            # validations each produce one or more results
            results => array_each(any(map +{
                id => undef,
                validation_id => $_->id,
                category => $_->module->category,
                component_id => ignore,
                device_id => 'TEST',
                hardware_product_id => $hardware_product->id,
                hint => ignore,
                message => ignore,
                order => ignore,
                status => any(qw(error fail pass)),
            }, @validations)),
        });
};

subtest 'system_uuid collisions' => sub {
    my $report_data = Mojo::JSON::from_json($report);
    $report_data->{serial_number} = 'i_was_here_first';

    my $existing_device = $t->generate_fixtures('device', { id => 'i_was_here_first' });

    $t->post_ok('/device_report', json => $report_data)
        ->status_is(400)
        ->json_cmp_deeply({ error => re(qr/no validations ran: .*duplicate key value violates unique constraint "device_system_uuid_key"/) });

    $t->post_ok('/device/i_was_here_first', json => $report_data)
        ->json_cmp_deeply({ error => re(qr/could not process report for device i_was_here_first.*duplicate key value violates unique constraint "device_system_uuid_key"/) });
};

done_testing;
