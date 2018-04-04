use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use DDP;
use Data::UUID;

use Conch::Model::Device;
use Conch::Model::ValidationPlan;
use Conch::Model::Validation;

use_ok("Conch::Model::ValidationResult");

use Conch::Model::ValidationState;

my $uuid  = Data::UUID->new;
my $pgtmp = mk_tmp_db() or die;
my $pg    = Conch::Pg->new( $pgtmp->uri );

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

BAIL_OUT("Could not create a validation plan and device ")
	unless $validation_plan->id && $device->id;

my $validation_state =
	Conch::Model::ValidationState->create( $device->id, $validation_plan->id );

my $validation = Conch::Model::Validation->create( 'test', 1, 'test validation',
	'Test::Validation' );

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

subtest "validation result lookup" => sub {
	ok( my $result1 = Conch::Model::ValidationResult->lookup( $result->id) );
	is_deeply($result, $result1);
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

	is(
		Conch::Model::ValidationResult->lookup( $result->id )->comparison_hash,
		Conch::Model::ValidationResult->lookup( $result2->id )->comparison_hash
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
