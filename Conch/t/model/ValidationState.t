use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use DDP;
use Data::UUID;

use Conch::Model::Device;
use Conch::Model::ValidationPlan;

use_ok("Conch::Model::ValidationState");

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

my $validation_state;
subtest "Create validation state" => sub {
	$validation_state =
		Conch::Model::ValidationState->create( $device->id, $validation_plan->id );
	isa_ok( $validation_state, 'Conch::Model::ValidationState' );
	ok( $validation_state->id );
	is( $validation_state->device_id,          $device->id );
	is( $validation_state->validation_plan_id, $validation_plan->id );
	ok( $validation_state->created );
	ok( !$validation_state->completed );
};

subtest "lookup validation state" => sub {
	my $maybe_validation_state =
		Conch::Model::ValidationState->lookup( $uuid->create_str );
	is( $maybe_validation_state, undef, 'unfound validation state is undef' );

	$maybe_validation_state =
		Conch::Model::ValidationState->lookup( $validation_state->id );
	is_deeply( $maybe_validation_state, $validation_state,
		'found validation state is same as created' );
};

subtest "modify validation state" => sub {
	is( $validation_state->completed,
		undef, 'Validation state does not have a completed value' );
	isa_ok( $validation_state->mark_completed(),
		'Conch::Model::ValidationState' );
	ok( $validation_state->completed,
		'Validation state now has a completed value' );
};

done_testing();
