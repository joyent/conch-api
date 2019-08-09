use v5.26;
use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;

my $t = Test::Conch->new;
$t->load_fixture('super_user');
$t->load_validation_plans([{
    name        => 'Conch v1 Legacy Plan: Server',
    description => 'Test Plan',
    validations => [ 'Conch::Validation::DeviceProductName' ],
}]);

$t->authenticate;

$t->get_ok('/validation')
    ->status_is(200)
    ->json_schema_is('Validations');

my $validation_id = $t->tx->res->json->[0]->{id};
my @validations = $t->tx->res->json->@*;

$t->get_ok('/validation_plan')
    ->status_is(200)
    ->json_schema_is('ValidationPlans')
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
    ->json_schema_is('ValidationPlan')
    ->json_is($validation_plans[0]);

$t->get_ok('/validation_plan/Conch v1 Legacy Plan: Server')
    ->status_is(200)
    ->json_schema_is('ValidationPlan')
    ->json_is($validation_plans[0]);

$t->get_ok('/validation_plan/'.$validation_plans[0]->{id}.'/validation')
    ->status_is(200)
    ->json_schema_is('Validations')
    ->json_is([ $validations[0] ]);

$t->get_ok('/validation_plan/Conch v1 Legacy Plan: Server/validation')
    ->status_is(200)
    ->json_schema_is('Validations')
    ->json_is([ $validations[0] ]);

$t->get_ok('/validation/'.$validation_id)
    ->status_is(200)
    ->json_schema_is('Validation')
    ->json_is($validations[0]);

$t->get_ok('/validation/'.$validations[0]->{name})
    ->status_is(200)
    ->json_schema_is('Validation')
    ->json_is($validations[0]);

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
