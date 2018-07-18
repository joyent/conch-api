use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Test::ConchTmpDB qw(mk_tmp_db);
use DDP;
use Data::UUID;

use Conch::Model::Device;

my $uuid = Data::UUID->new;

use_ok("Conch::Model::Validation");

use Conch::Model::Validation;

my $pgtmp = mk_tmp_db();
$pgtmp or die;
my $pg = Conch::Pg->new( $pgtmp->uri );

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
		vendor => $hardware_vendor_id,
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
		product_id    => $hardware_product_id,
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

my $device = Conch::Model::Device->create( 'coffee', $hardware_product_id );

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

subtest "upsert validation" => sub {

	subtest "Unchanged upsert returns undef " => sub {
		my $upsert_validation =
			Conch::Model::Validation->upsert( 'test', 1, 'test validation',
			'Conch::Validation::Test' );
		ok( !defined($upsert_validation) );
	};

	subtest "Upsert existing validation" => sub {
		my $upsert_validation =
			Conch::Model::Validation->upsert( 'test', 1, 'upsert test validation',
			'Conch::Validation::Test' );
		isa_ok( $upsert_validation, 'Conch::Model::Validation' );
		is( $upsert_validation->id, $validation->id,
			'Has same ID as previous Validation' );
		is( $upsert_validation->name,        'test' );
		is( $upsert_validation->version,     1 );
		is( $upsert_validation->description, 'upsert test validation' );
	};
	subtest "Upsert new validation" => sub {

		# new version
		my $upsert_validation =
			Conch::Model::Validation->upsert( 'test', 2, 'upsert new validation',
			'Conch::Validation::Foobar' );
		isa_ok( $upsert_validation, 'Conch::Model::Validation' );
		isnt( $upsert_validation->id, $validation->id,
			'Has different ID as previous Validation' );
		is( $upsert_validation->name,        'test' );
		is( $upsert_validation->version,     2 );
		is( $upsert_validation->description, 'upsert new validation' );
	};
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

	throws_ok(
		sub {
			$validation->build_device_validation( $device, $hw_product, undef,
				undef );
		},
		qr/Unable to create validation 'Conch::Validation::Test'/,
		'The fake validation must throw an exception because it can not be created'
	);

	require Conch::Validation::DeviceProductName;
	my $real_validation = Conch::Model::Validation->create(
		'product_name', 1,
		'real validation',
		'Conch::Validation::DeviceProductName'
	);

	my $device_validation;
	lives_ok {
		$device_validation =
			$real_validation->build_device_validation( $device, $hw_product, undef,
			undef );
	};

	isa_ok( $device_validation, 'Conch::Validation' );
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
