use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Test::ConchTmpDB qw(mk_tmp_db);
use DDP;
use Data::UUID;

use Conch::Models;
use Conch::Pg;

my $uuid = Data::UUID->new;

use_ok("Conch::Model::ValidationPlan");

use Conch::Model::ValidationPlan;
require Conch::Validation::DeviceProductName;

my $pgtmp = mk_tmp_db();
$pgtmp or die;
my $pg = Conch::Pg->new( $pgtmp->uri );

use Test::Conch;
my $t = Test::Conch->new(pg => $pgtmp);

# formerly: Conch::Model::Validation->lookup_by_name_and_version('product_name', 1);
my $real_validation = Conch::Model::Validation->new(
	$t->load_validation('Conch::Validation::DeviceProductName')->get_columns
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
		hardware_vendor_id => $hardware_vendor_id,
		generation_name => 'Joyent-G1',
	},
	{ returning => ['id'] }
)->hash->{id};

my $zpool_profile_id = $pg->db->insert(
	'zpool_profile',
	{ name      => 'test' },
	{ returning => ['id'] }
)->hash->{id};

my $hardware_profile_id = $pg->db->insert(
	'hardware_product_profile',
	{
		hardware_product_id    => $hardware_product_id,
		zpool_id      => $zpool_profile_id,
		rack_unit     => 1,
		purpose       => 'test',
		bios_firmware => 'test',
		cpu_num       => 2,
		cpu_type      => 'test',
		dimms_num     => 3,
		ram_total     => 4,
		nics_num      => 5,
		usb_num       => 6

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

my $validation_plan;
subtest "Create validation plan" => sub {
	# formerly Conch::Model::ValidationPlan->create( 'test', 'test validation plan' );
	$validation_plan = Conch::Model::ValidationPlan->new(
		$t->app->db_validation_plans->create({
			name => 'test',
			description => 'test validation plan',
		})->discard_changes->get_columns
	);

	isa_ok( $validation_plan, 'Conch::Model::ValidationPlan' );
	ok( $validation_plan->id );
	is( $validation_plan->name,        'test' );
	is( $validation_plan->description, 'test validation plan' );
};

subtest "lookup validation plan" => sub {

	my $data = $t->app->db_validation_plans->hri->search({ id => $uuid->create_str })->single;
	my $maybe_validation_plan = $data ? Conch::Model::ValidationPlan->new($data) : undef;
	is( $maybe_validation_plan, undef, 'unfound validation plan is undef' );

	$data = $t->app->db_validation_plans->hri->search({ id => $validation_plan->id })->single;
	$maybe_validation_plan = $data ? Conch::Model::ValidationPlan->new($data) : undef;
	is_deeply( $maybe_validation_plan, $validation_plan,
		'found validation plan is same as created' );
};

subtest "associated validation" => sub {
	# formerly $validation_plan->validation_ids
	is_deeply(
		[ $t->app->db_validation_plan_members->search({ validation_plan_id => $validation_plan->id })->get_column('validation_id')->all ],
		[],
		'No associated validations' );
	my $validation = Conch::Model::Validation->new(
		$t->app->db_validations->create({
			name => 'test',
			version => 1,
			description => 'test validation',
			module => 'Conch::Validation::Test',
		})->get_columns
	);

	# formerly $validation_plan->drop_validations
	$t->app->db_validation_plans->search({ id => $validation->id })->delete;
};

subtest "run validation plan" => sub {
	$validation_plan->log($t->app->log);
	throws_ok(
		sub {
			$validation_plan->run_with_state(
				undef,
				$device_report->id,
				{}
			);
		},
		qr/Device must be defined/
	);
	throws_ok(
		sub {
			$validation_plan->run_with_state(
				$device,
				$device_report->id,
				'bad'
			);
		},
		qr/Validation data must be a hashref/
	);

	is( scalar $validation_plan->validations->@*,
		0, 'Validation plan should have no validations' );
	my $new_state = $validation_plan->run_with_state(
		$device,
		$device_report->id,
		{}
	);
	ok( $new_state->completed );
	is( scalar $new_state->validation_results->@*, 0 );
	is( $new_state->status, 'pass', 'Passes though no results stored' );


	# formerly $validation_plan->add_validation($real_validation)
	$t->app->db_validation_plans->find($validation_plan->id)
		->find_or_create_related('validation_plan_members', { validation_id => $real_validation->id });

	my $error_state = $validation_plan->run_with_state(
		$device,
		$device_report->id,
		{}
	);
	is( scalar $error_state->validation_results->@*, 1 );
	is( $error_state->status, 'error',
		'Validation state should be error because result errored' );

	my $fail_state = $validation_plan->run_with_state(
		$device,
		$device_report->id,
		{ product_name => 'bad' }
	);
	is( scalar $fail_state->validation_results->@*, 1 );
	is( $fail_state->status, 'fail',
		'Validation state should be fail because result failed' );

	my $pass_state = $validation_plan->run_with_state(
		$device,
		$device_report->id,
		{ product_name => 'Joyent-G1' }
	);
	is( scalar $pass_state->validation_results->@*, 1 );
	is( $pass_state->status, 'pass',
		'Validation state should be pass because all results passed' );
};

done_testing();
