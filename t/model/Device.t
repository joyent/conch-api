use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB qw(mk_tmp_db);

use Try::Tiny;

use_ok("Conch::Model::Device");

use Data::UUID;

use Conch::Pg;

my $pgtmp = mk_tmp_db();
$pgtmp or die;
my $schema = Test::ConchTmpDB->schema($pgtmp);

my $pg    = Conch::Pg->new($pgtmp->uri);

my $uuid = Data::UUID->new;

my ( $hw_vendor_id, $hw_product_id );

try {
	$hw_vendor_id = $pg->db->insert(
		'hardware_vendor',
		{ name      => 'test vendor' },
		{ returning => ['id'] }
	)->hash->{id};

	$hw_product_id = $pg->db->insert(
		'hardware_product',
		{
			name   => 'test hw product',
			alias  => 'alias',
			hardware_vendor_id => $hw_vendor_id
		},
		{ returning => ['id'] }
	)->hash->{id};
}
catch {
	BAIL_OUT("Setup failed: $_");
};

my $d;
my $device_serial = 'c0ff33';
subtest "Create new device" => sub {

	$d = Conch::Model::Device->create( $device_serial, $hw_product_id );

	isa_ok( $d, "Conch::Model::Device" );
	is( $d->id,    $device_serial, "New device ID matches expectations" );
	is( $d->state, "UNKNOWN",      "New device state matches expectations" );

	is( $d->hardware_product_id, $hw_product_id,
		"New device hardware product id matches expectations" );

	my $duplicate =
		Conch::Model::Device->create( $device_serial, $hw_product_id );
	is( $duplicate, undef, "Duplicate creation attempt fails" );
};

my $user;
subtest "Lookup" => sub {
	my $d2 = Conch::Model::Device->lookup( $d->id );
	isa_ok( $d2, "Conch::Model::Device" );
	is_deeply( $d2, $d, "Looked-up device matches expectations" );

	is(
		Conch::Model::Device->lookup( 'bad device id' ),
		undef, "Lookup for bad device fails",
	);
};

done_testing();
