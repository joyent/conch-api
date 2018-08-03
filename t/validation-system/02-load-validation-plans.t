use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Test::ConchTmpDB qw(mk_tmp_db);

use Conch::ValidationSystem;
use Conch::Model::Device;
use Conch::Model::Validation;
use Conch::Model::ValidationPlan;

use Test::Conch;
my $t = Test::Conch->new();

my $logger = $t->app->log;

my $validation_plan_config = [
	{
		name        => 'Test validation plan 1',
		description => 'Test validation plan',
		validations => [ { name => 'product_name', version => 1 } ]
	},
	{
		name        => 'Test validation plan 2',
		description => 'Test validation plan',
		validations => [
			{ name => 'product_name', version => 1 },
			{ name => 'cpu_count',    version => 1 }
		]
	}
];

my @loaded_plans = Conch::ValidationSystem->load_validation_plans(
	$validation_plan_config,
	$logger
);

is( scalar @loaded_plans, 2, '2 plans returned' );

my $validation_plans = Conch::Model::ValidationPlan->list;

is_deeply( \@loaded_plans, $validation_plans,
	'loaded plans loaded match plans stored' );

my ( $plan1, $plan2 ) = @loaded_plans;

is( scalar $plan1->validations->@*, 1, '1 validation in plan 1' );

is( scalar $plan2->validations->@*, 2, '2 validations in plan 2' );

done_testing();
