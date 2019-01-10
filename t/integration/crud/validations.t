use v5.26;
use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;

my $t = Test::Conch->new;
$t->load_fixture('conch_user_global_workspace');
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
            id => ignore,
            name => 'Conch v1 Legacy Plan: Server',
            description => 'Test Plan',
            created => ignore,
        },
    ]);

my $validation_plan_id = $t->tx->res->json->[0]->{id};
my @validation_plans = $t->tx->res->json->@*;


SKIP: {
    skip 'endpoints that mutate validation plans have been disabled', 26;
    $t->post_ok('/validation_plan', json => { name => 'my_test_plan', description => 'another test plan' })
        ->status_is(303);

    $t->get_ok($t->tx->res->headers->location)
        ->status_is(200)
        ->json_schema_is('ValidationPlan');

    $validation_plan_id = $t->tx->res->json->{id};

    $t->get_ok('/validation_plan')
        ->status_is(200)
        ->json_schema_is('ValidationPlans')
        ->json_cmp_deeply([
            @validation_plans,
            {
                id => $validation_plan_id,
                name => 'my_test_plan',
                description => 'another test plan',
                created => ignore,
            },
        ]);

    @validation_plans = $t->tx->res->json->@*;

    $t->get_ok("/validation_plan/$validation_plan_id")
        ->status_is(200)
        ->json_schema_is('ValidationPlan')
        ->json_is($validation_plans[1]);

    $t->post_ok("/validation_plan/$validation_plan_id/validation",
            json => { id => $validation_id })
        ->status_is(204);

    $t->post_ok("/validation_plan/$validation_plan_id/validation",
            json => { id => $validation_id })
        ->status_is(204, 'adding a validation to a plan twice is not an error');

    $t->post_ok('/validation_plan',
            json => { name => 'my_test_plan', description => 'test plan' })
        ->status_is(409)
        ->json_is({ error => "A Validation Plan already exists with the name 'my_test_plan'" });

    $t->get_ok('/validation_plan')
        ->status_is(200)
        ->json_schema_is('ValidationPlans')
        ->json_is(\@validation_plans);

    $t->get_ok("/validation_plan/$validation_plan_id/validation")
        ->status_is(200)
        ->json_schema_is('Validations')
        ->json_is([ $validations[0] ]);

    $t->delete_ok("/validation_plan/$validation_plan_id/validation/$validation_id")
        ->status_is(204);

    $t->get_ok("/validation_plan/$validation_plan_id/validation")
        ->status_is(200)
        ->json_is('', []);
} # end SKIP


done_testing;
# vim: set ts=4 sts=4 sw=4 et :
