use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Test::ConchTmpDB qw(mk_tmp_db);

use DDP;
use Data::UUID;

use Conch::Model::ValidationPlan;
use Conch::Model::Validation;

use_ok("Conch::Model::ValidationState");

use Conch::Model::ValidationState;

my $uuid  = Data::UUID->new;
my $pgtmp = mk_tmp_db();
$pgtmp or die;
my $pg    = Conch::Pg->new( $pgtmp->uri );

use Test::Conch;
my $t = Test::Conch->new(pg => $pgtmp);

# formerly: Conch::Model::Validation->lookup_by_name_and_version('product_name', 1);
my $real_validation = Conch::Model::Validation->new(
	$t->load_validation('Conch::Validation::DeviceProductName')->get_columns
);

# formerly Conch::Model::ValidationPlan->create( 'test', 'test validation plan' );
my $validation_plan = Conch::Model::ValidationPlan->new(
	$t->app->db_validation_plans->create({
		name => 'test',
		description => 'test validation plan',
	})->discard_changes->get_columns
);
$validation_plan->log($t->app->log);

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

BAIL_OUT("Could not create a validation plan and device ")
	unless $validation_plan->id && $device->id;

my $validation_state;
subtest "Create validation state" => sub {
	$validation_state =
		Conch::Model::ValidationState->create( $device->id, $device_report->id, $validation_plan->id );
	isa_ok( $validation_state, 'Conch::Model::ValidationState' );
	ok( $validation_state->id );
	is( $validation_state->device_id,          $device->id );
	is( $validation_state->validation_plan_id, $validation_plan->id );
	ok( $validation_state->created );
	ok( !$validation_state->completed );
};

subtest "modify validation state" => sub {
	is( $validation_state->completed,
		undef, 'Validation state does not have a completed value' );
	isa_ok( $validation_state->mark_completed('pass'),
		'Conch::Model::ValidationState' );
	ok( $validation_state->completed,
		'Validation state now has a completed value' );
};

subtest "latest validation state" => sub {
	my $latest =
		Conch::Model::ValidationState->latest_for_device_plan(
		$device->id, $validation_plan->id );
	isa_ok( $latest, 'Conch::Model::ValidationState' );

	my $new_state =
		Conch::Model::ValidationState->create( $device->id, $device_report->id, $validation_plan->id );
	$new_state->mark_completed('pass');

	my $new_latest =
		Conch::Model::ValidationState->latest_for_device_plan(
		$device->id, $validation_plan->id );
	is_deeply( $new_state, $new_latest );
};

subtest "validation results" => sub {
	is_deeply( $validation_state->validation_results, [] );

	my $validation = Conch::Model::Validation->new(
		$t->app->db_validations->create({
			name => 'test',
			version => 1,
			description => 'test validation',
			module => 'Test::Validation',
		})->TO_JSON->%*
	);

	my $result = Conch::Model::ValidationResult->new(
		device_id           => $device->id,
		validation_id       => $validation->id,
		hardware_product_id => $hardware_product_id,
		message             => 'foobar',
		category            => 'TEST',
		status              => 'fail',
		result_order        => 0
	)->record;

	ok( $validation_state->add_validation_result($result) );
	is_deeply( $validation_state->validation_results, [$result] );

	# repeated addition is idempotent
	ok( $validation_state->add_validation_result($result) );
	is_deeply( $validation_state->validation_results, [$result] );
};

require Conch::Validation::DeviceProductName;
# formerly $validation_plan->add_validation($real_validation)
$t->app->db_validation_plans->find($validation_plan->id)
	->find_or_create_related('validation_plan_members', { validation_id => $real_validation->id });

subtest 'latest_completed_grouped_states_for_device' => sub {
	my $latest_state = $validation_plan->run_with_state(
		$device,
		$device_report->id,
		{ product_name => 'test hw product' }
	);
	# formerly Conch::Model::ValidationState->latest_completed_grouped_states_for_device($device->id);
	my $groups = [
		map {
			my $state = $_;
			+{
				state => Conch::Model::ValidationState->new($state->get_columns),
				results => [
					map {
						Conch::Model::ValidationResult->new($_->validation_result->get_columns)
					} $state->validation_state_members
				],
			}
		}
		$t->app->db_devices->search({ 'device.id' => $device->id })
			->search_related('validation_states')
			->latest_completed_state_per_plan
			->prefetch({ validation_state_members => 'validation_result' })
			->all
	];

	my $results = $latest_state->validation_results;
	is( scalar $groups->@*, 1 );
	is_deeply( $groups->[0]->{state},   $latest_state );
	is_deeply( $groups->[0]->{results}, $results );

	# formerly Conch::Model::ValidationPlan->create( 'test_1', 'test validation plan' );
	my $validation_plan_1 = Conch::Model::ValidationPlan->new(
		$t->app->db_validation_plans->create({
			name => 'test_1',
			description => 'test validation plan',
		})->discard_changes->get_columns
	);

	$validation_plan_1->log($t->app->log);

	# formerly $validation_plan_1->add_validation($real_validation)
	$t->app->db_validation_plans->find($validation_plan_1->id)
		->find_or_create_related('validation_plan_members', { validation_id => $real_validation->id });

	my $new_state =
		$validation_plan_1->run_with_state(
			$device,
			$device_report->id,
			{}
		);
	my $new_results = $new_state->validation_results;
	$groups = [
		map {
			my $state = $_;
			+{
				state => Conch::Model::ValidationState->new($state->get_columns),
				results => [
					map {
						Conch::Model::ValidationResult->new($_->validation_result->get_columns)
					} $state->validation_state_members
				],
			}
		}
		$t->app->db_devices->search({ 'device.id' => $device->id })
			->search_related('validation_states')
			->latest_completed_state_per_plan
			->prefetch({ validation_state_members => 'validation_result' })
			->all
	];

	is( scalar $groups->@*, 2 );
	is_deeply(
		$groups,
		[
			{
				state   => $new_state,
				results => $new_results
			},
			{
				state   => $latest_state,
				results => $results
			},
		],
		'Groups return in sorted order by most recent completed state first'
	);
};


done_testing();
