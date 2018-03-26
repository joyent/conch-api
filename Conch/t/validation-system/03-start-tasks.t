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

my $uuid   = Data::UUID->new;
my $pgtmp  = mk_tmp_db() or die;
my $pg     = Conch::Pg->new( $pgtmp->uri );
my $minion = Conch::Minion->new;

my $num_validations_loaded =
	Conch::ValidationSystem->load_validations(
	Mojo::Log->new( level => 'warn' ) );

my $validation_plan =
	Conch::Model::ValidationPlan->create( 'test', 'test validation plan' );

my $hardware_vendor_id = $pg->db->insert(
	'hardware_vendor',
	{ name      => 'test vendor' },
	{ returning => ['id'] }
)->hash->{id};

my $hardware_product_id = $pg->db->insert(
	'hardware_product',
	{
		name   => 'test hw product',
		alias  => 'alias',
		vendor => $hardware_vendor_id
	},
	{ returning => ['id'] }
)->hash->{id};

my $device = Conch::Model::Device->create( 'coffee', $hardware_product_id );

my $validation =
	Conch::Model::Validation->lookup_by_name_and_version( 'product_name', 1 );

$validation_plan->add_validation($validation);

subtest "Run validation plan" => sub {
	my $new_validation_state =
		Conch::ValidationSystem->run_validation_plan( 'coffee',
		$validation_plan->id, {} );

	my $stats = $minion->stats;
	is( $stats->{enqueued_jobs}, 2, 'jobs enqueued' );
	is( $stats->{inactive_jobs}, 2, 'jobs inactive' );
	is( $stats->{finished_jobs}, 0, 'jobs not finished' );

	ok( !defined( $new_validation_state->completed ) );

	Conch::ValidationSystem->start_tasks;

	$minion->perform_jobs;

	$stats = $minion->stats;
	is( $stats->{finished_jobs}, 2, 'jobs finished' );
	is( $stats->{failed_jobs},   0, 'no failed jobs' );

	# refresh validation state
	$new_validation_state =
		Conch::Model::ValidationState->lookup( $new_validation_state->id );
	ok( defined( $new_validation_state->completed ) );
};

subtest "Verify Validations run to completion" => sub {
	my $validation_state =
		Conch::Model::ValidationState->create( $device->id, $validation_plan->id );

	$minion->minion->reset;

	my $id = $minion->minion->enqueue(
		validation => [ $validation->id, $device->id, {}, $validation_state->id ] );

	$minion->perform_jobs;
	my $stats = $minion->stats;
	is( $stats->{finished_jobs}, 1, 'job finished' );

	my $result = $minion->minion->job($id)->info->{result};
	is( scalar( $result->@* ),  1 );
	is( $result->[0]->{status}, 'error' );
};

done_testing();
