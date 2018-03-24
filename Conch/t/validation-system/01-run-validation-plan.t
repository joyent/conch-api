use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Test::ConchTmpDB;
use Conch::Pg;
use Minion;
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
	unless $validation_plan && $validation_plan->id && $device->id;

throws_ok(
	sub { Conch::ValidationSystem->run_validation_plan( undef, undef, undef ); },
	qr/Device ID must be defined/
);
throws_ok(
	sub {
		Conch::ValidationSystem->run_validation_plan( 'foobar', undef, undef );
	},
	qr/Validation Plan ID must be defined/
);
throws_ok(
	sub {
		Conch::ValidationSystem->run_validation_plan( 'foobar', '1234', undef );
	},
	qr/Validation data must be a hashref/
);
throws_ok(
	sub { Conch::ValidationSystem->run_validation_plan( 'foobar', '1234', {} ); },
	qr/No device exists with ID 'foobar'/
);
throws_ok(
	sub {
		Conch::ValidationSystem->run_validation_plan( 'coffee', $uuid->create_str,
			{} );
	},
	qr/No Validation Plan found with ID/
);

throws_ok(
	sub {
		Conch::ValidationSystem->run_validation_plan( 'coffee',
			$validation_plan->id, {} );
	},
	qr/Validation Plan .+ is not associated with any validations/
);

my $validation = Conch::Model::Validation->create( 'test', 1, 'test validation',
	'Test::Validation' );

$validation_plan->add_validation($validation);

my $new_validation_state =
	Conch::ValidationSystem->run_validation_plan( 'coffee', $validation_plan->id,
	{} );

isa_ok( $new_validation_state, 'Conch::Model::ValidationState' );
ok( $new_validation_state->id );

my $stats = $minion->stats;
is( $stats->{enqueued_jobs}, 2 );

done_testing();
