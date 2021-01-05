use v5.26;
use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;
use Conch::UUID;

my $t = Test::Conch->new;
$t->load_fixture('super_user');
$t->load_validation_plans([{
    name        => 'Conch v1 Legacy Plan: Server',
    description => 'Test Plan',
    validations => [ 'Conch::Validation::DeviceProductName' ],
}]);

$t->authenticate;

my @validations = map $_->TO_JSON, $t->app->db_legacy_validations->order_by([ qw(name version) ]);

$t->get_ok('/validation_plan')
    ->status_is(200)
    ->json_schema_is('LegacyValidationPlans')
    ->json_cmp_deeply([
        {
            id => re(Conch::UUID::UUID_FORMAT),
            name => 'Conch v1 Legacy Plan: Server',
            description => 'Test Plan',
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        },
    ]);

my $validation_plan_id = $t->tx->res->json->[0]->{id};
my @validation_plans = $t->tx->res->json->@*;

$t->get_ok('/validation_plan/'.$validation_plans[0]->{id})
    ->status_is(200)
    ->json_schema_is('LegacyValidationPlan')
    ->json_is($validation_plans[0]);

$t->get_ok('/validation_plan/Conch v1 Legacy Plan: Server')
    ->status_is(200)
    ->json_schema_is('LegacyValidationPlan')
    ->json_is($validation_plans[0]);

$t->get_ok('/validation_plan/'.$validation_plans[0]->{id}.'/validation')
    ->status_is(200)
    ->json_schema_is('LegacyValidations')
    ->json_is([ $validations[0] ]);

$t->get_ok('/validation_plan/Conch v1 Legacy Plan: Server/validation')
    ->status_is(200)
    ->json_schema_is('LegacyValidations')
    ->json_is([ $validations[0] ]);

done_testing;
# vim: set sts=2 sw=2 et :
