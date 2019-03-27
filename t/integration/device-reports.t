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

# matches report's product_name = Joyent-G1
$t->load_fixture('hardware_product_profile_compute');
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
    my $report = path('t/integration/resource/passing-device-report.json')->slurp_utf8;
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

done_testing;
