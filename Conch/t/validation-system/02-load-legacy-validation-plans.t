use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Test::ConchTmpDB;
use Conch::Pg;
use Data::UUID;
use DDP;

use Conch::ValidationSystem;
use Conch::Model::Device;
use Conch::Model::Validation;
use Conch::Model::ValidationPlan;

my $uuid  = Data::UUID->new;
my $pgtmp = mk_tmp_db() or die;
my $pg    = Conch::Pg->new( $pgtmp->uri );

my $logger = Mojo::Log->new( level => 'warn' );

Conch::ValidationSystem->load_validations($logger);
my @loaded_plans = Conch::ValidationSystem->load_legacy_plans($logger);

is( scalar @loaded_plans, 2, '2 plans returned' );

my $validation_plans = Conch::Model::ValidationPlan->list;

is_deeply( \@loaded_plans, $validation_plans,
	'loaded plans loaded match plans stored' );

my ( $switch_plan, $server_plan ) = @loaded_plans;

is( scalar $switch_plan->validations->@*, 6, '6 validations in switch plan' );

is( scalar $server_plan->validations->@*, 15, '15 validations in server plan' );

done_testing();
