use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB qw(mk_tmp_db);
use DDP;
use Data::UUID;

use Conch::Model::ValidationPlan;
use Conch::Model::Validation;

use_ok("Conch::Model::ValidationResult");

use Conch::Model::ValidationState;

my $uuid  = Data::UUID->new;
my $pgtmp = mk_tmp_db();
$pgtmp or die;
my $pg    = Conch::Pg->new( $pgtmp->uri );

use Test::Conch;
my $t = Test::Conch->new(pg => $pgtmp);

# formerly Conch::Model::ValidationPlan->create( 'test', 'test validation plan' );
my $validation_plan = Conch::Model::ValidationPlan->new(
	$t->app->db_validation_plans->create({
		name => 'test',
		description => 'test validation plan',
	})->discard_changes->get_columns
);

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
		hardware_vendor_id => $hardware_vendor_id
	},
	{ returning => ['id'] }
)->hash->{id};

my $device = $t->app->db_devices->create({
	id => 'coffee',
	hardware_product_id => $hardware_product_id,
	state => 'UNKNOWN',
	health => 'UNKNOWN',
});
my $device_report = $t->app->db_device_reports->create({ device_id => 'coffee', report => '{}' });

BAIL_OUT("Could not create a validation plan and device ")
	unless $validation_plan->id && $device->id;

my $validation_state =
	Conch::Model::ValidationState->create( $device->id, $device_report->id, $validation_plan->id );

my $validation = Conch::Model::Validation->new(
	$t->app->db_validations->create({
		name => 'test',
		version => 1,
		description => 'test validation',
		module => 'Test::Validation',
	})->discard_changes->get_columns
);

my $result;
subtest "validation result new " => sub {
	$result = Conch::Model::ValidationResult->new(
		device_id           => $device->id,
		validation_id       => $validation->id,
		hardware_product_id => $hardware_product_id,
		message             => 'foobar',
		category            => 'TEST',
		status              => 'fail',
		result_order        => 0
	);
	isa_ok( $result, 'Conch::Model::ValidationResult' );
	ok( !defined( $result->id ) );
};

subtest "validation result record" => sub {
	ok( $result->record );
	ok( defined( $result->id ) );
};

subtest "validation result comparison_hash" => sub {

	my $result2 = Conch::Model::ValidationResult->new(
		device_id           => $device->id,
		validation_id       => $validation->id,
		hardware_product_id => $hardware_product_id,
		message             => 'foobar',
		category            => 'TEST',
		status              => 'fail',
		result_order        => 0
	);
	is( $result->comparison_hash, $result2->comparison_hash );
	$result2->record;

	my $rs = $t->app->db_validation_results;
	is(
		Conch::Model::ValidationResult->new( $rs->find($result->id)->discard_changes->get_columns )->comparison_hash,
		Conch::Model::ValidationResult->new( $rs->find($result2->id)->discard_changes->get_columns )->comparison_hash
	);

	my $result3 = Conch::Model::ValidationResult->new(
		device_id           => $device->id,
		validation_id       => $validation->id,
		hardware_product_id => $hardware_product_id,
		message             => 'Different message',
		category            => 'TEST',
		status              => 'fail',
		result_order        => 0
	);

	isnt( $result->comparison_hash, $result3->comparison_hash );
};

done_testing();
