use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use DDP;
use Data::UUID;

my $uuid = Data::UUID->new;

use_ok("Conch::Model::Validation");

use Conch::Model::Validation;

use Test::Conch;
my $t = Test::Conch->new(legacy_db => 1);
my $pg = Conch::Pg->new( $t->pg );

my $validation;

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

subtest "Create validation" => sub {
	$validation = Conch::Model::Validation->create( 'test', 1, 'test validation',
		'Conch::Validation::Test' );
	isa_ok( $validation, 'Conch::Model::Validation' );
};

subtest "lookup validation" => sub {
	my $maybe_validation = Conch::Model::Validation->lookup( $uuid->create_str );
	is( $maybe_validation, undef, 'unfound validation is undef' );

	$maybe_validation = Conch::Model::Validation->lookup( $validation->id );
	is_deeply( $maybe_validation, $validation,
		'found validation is same as created' );
};

subtest "lookup validation by name and version" => sub {
	my $maybe_validation =
		Conch::Model::Validation->lookup_by_name_and_version( 'test', 1 );
	is_deeply( $maybe_validation, $validation,
		'found validation is same as created' );

	$maybe_validation =
		Conch::Model::Validation->lookup_by_name_and_version( 'not found', 1 );
	is( $maybe_validation, undef, 'unfound validation is undef' );

};

subtest "build_device_validation" => sub {
	my $hw_product = Conch::Model::HardwareProduct->lookup($hardware_product_id);

	throws_ok(
		sub {
			$validation->build_device_validation( undef, $hw_product, undef, undef );
		},
		qr/Device must be defined/
	);

	throws_ok(
		sub { $validation->build_device_validation( $device, undef, undef, undef ) }
		,
		qr/Hardware product must be defined/
	);

	# formerly: Conch::Model::Validation->lookup_by_name_and_version('product_name', 1);
	my $real_validation = Conch::Model::Validation->new(
		$t->load_validation('Conch::Validation::DeviceProductName')->get_columns
	);
	$real_validation->log($t->app->log);

	my $device_validation;
	lives_ok {
		$device_validation =
			$real_validation->build_device_validation( $device, $hw_product, undef,
			undef );
	};

	isa_ok( $device_validation, 'Conch::Validation' );
	$device_validation->log($t->app->log);
	my $results = $device_validation->run( { product_name => 'Joyent-G1' } )
			->validation_results;
	is( scalar @$results, 1 );

	# 'run_validation_for_device' is a convenience function for building and
	# running a single validation and returning results with a given device
	subtest "run_validation_for_device" => sub {
		my $run_results;
		lives_ok {
			$run_results = $real_validation->run_validation_for_device( $device,
				{ product_name => 'Joyent-G1' } );
		};
		is_deeply( $run_results, $results, 'Results should be the same' );
	};
};

done_testing();
