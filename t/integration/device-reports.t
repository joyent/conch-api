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
                hardware_product_id => $hardware_product->id,
                hint => ignore,
                message => ignore,
                order => ignore,
                status => any(qw(error fail pass)),
            }, @validations)),
        });
};

done_testing;
