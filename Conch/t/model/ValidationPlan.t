use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB qw(mk_tmp_db);
use Mojo::Pg;

use DDP;
use Data::UUID;

use Conch::Model::Validation;
use Conch::Pg;

my $uuid = Data::UUID->new;

use_ok("Conch::Model::ValidationPlan");

use Conch::Model::ValidationPlan;

my $pgtmp = mk_tmp_db();
$pgtmp or die;
my $pg = Conch::Pg->new( $pgtmp->uri );

my $validation_plan;
subtest "Create validation plan" => sub {
	$validation_plan =
		Conch::Model::ValidationPlan->create( 'test', 'test validation plan' );
	isa_ok( $validation_plan, 'Conch::Model::ValidationPlan' );
	ok( $validation_plan->id );
	is( $validation_plan->name,        'test' );
	is( $validation_plan->description, 'test validation plan' );
};

subtest "lookup validation plan" => sub {
	my $maybe_validation_plan =
		Conch::Model::ValidationPlan->lookup( $uuid->create_str );
	is( $maybe_validation_plan, undef, 'unfound validation plan is undef' );

	$maybe_validation_plan =
		Conch::Model::ValidationPlan->lookup( $validation_plan->id );
	is_deeply( $maybe_validation_plan, $validation_plan,
		'found validation plan is same as created' );
};

subtest "associated validation" => sub {
	is_deeply( $validation_plan->validation_ids, [],
		'No associated validations' );
	my $validation =
		Conch::Model::Validation->create( 'test', 1, 'test validation',
		'Test::Validation' );

	is( $validation_plan->add_validation($validation),
		$validation_plan, 'add validation; fluid interface' );
	is_deeply(
		$validation_plan->validation_ids,
		[ $validation->id ],
		'associated validation IDs'
	);

	is_deeply( $validation_plan->validations,
		[$validation], 'associated validation' );

	is( $validation_plan->add_validation( $validation->id ),
		$validation_plan, 'can also use ID' );

	is( $validation_plan->remove_validation($validation),
		$validation_plan, 'remove validation; fluid interface' );

	is_deeply( $validation_plan->validation_ids, [], 'associated validation' );

	is( $validation_plan->add_validation( $validation->id ),
		$validation_plan, 'can also use ID' );
	is_deeply(
		$validation_plan->validation_ids,
		[ $validation->id ],
		'associated validation'
	);

	is( $validation_plan->drop_validations,
		$validation_plan, 'drop all validation associations; fluid interface' );

	is_deeply( $validation_plan->validation_ids, [], 'no associated validation' );
};

done_testing();
