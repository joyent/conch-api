use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB qw(mk_tmp_db);

use_ok("Conch::Model::HardwareProduct");

use Data::UUID;

my $pgtmp = mk_tmp_db();
$pgtmp or die;
my $pg = Conch::Pg->new( $pgtmp->uri );

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

my $zpool_profile_id = $pg->db->insert(
	'zpool_profile',
	{ name      => 'test' },
	{ returning => ['id'] }
)->hash->{id};

my %hw_profile_values = (
	rack_unit     => 1,
	purpose       => 'test',
	bios_firmware => 'test',
	cpu_num       => 2,
	cpu_type      => 'test',
	dimms_num     => 3,
	ram_total     => 4,
	nics_num      => 5,
	usb_num       => 6
);

my $hardware_profile_id = $pg->db->insert(
	'hardware_product_profile',
	{
		product_id => $hardware_product_id,
		zpool_id   => $zpool_profile_id,
		%hw_profile_values
	},
	{ returning => ['id'] }
)->hash->{id};

new_ok('Conch::Model::HardwareProduct');
my $hw_product_model = new_ok("Conch::Model::HardwareProduct");

subtest 'list hardware products' => sub {
	my $hw_products = $hw_product_model->list;
	isa_ok( $hw_products, 'ARRAY' );
	is( scalar @$hw_products, 1, 'Contains 1 hardware product' );
	my $hw_product = $hw_products->[0];

	isa_ok( $hw_product,                 'Conch::Class::HardwareProduct' );
	isa_ok( $hw_product->profile,        'Conch::Class::HardwareProductProfile' );
	isa_ok( $hw_product->profile->zpool, 'Conch::Class::ZpoolProfile' );

	is( $hw_product->profile->id, $hardware_profile_id, "Profile IDs match" );
	is( $hw_product->profile->bios_firmware, "test", "BIOS Firmware" );
	is( $hw_product->profile->zpool->id, $zpool_profile_id, "Zpool profile ID" );
};

subtest 'lookup hardware product' => sub {
	my $hw_product = $hw_product_model->lookup($hardware_product_id);
	isa_ok( $hw_product,                 'Conch::Class::HardwareProduct' );
	isa_ok( $hw_product->profile,        'Conch::Class::HardwareProductProfile' );
	isa_ok( $hw_product->profile->zpool, 'Conch::Class::ZpoolProfile' );

	is( $hw_product->profile->id, $hardware_profile_id, "Profile IDs match" );
	my %profile_values = %{ $hw_product->profile }{ keys %hw_profile_values };
	is_deeply( { %profile_values }, { %hw_profile_values });
	is( $hw_product->profile->zpool->id, $zpool_profile_id, "Zpool profile ID" );
};

done_testing();
