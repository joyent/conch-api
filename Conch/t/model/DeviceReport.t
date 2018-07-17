use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB qw(mk_tmp_db);
use Mojo::Pg;

use_ok "Conch::Model::Device";
use_ok "Conch::Model::DeviceReport";

use Conch::Pg;

my $pgtmp = mk_tmp_db();
$pgtmp or die;
my $pg    = Conch::Pg->new( $pgtmp->uri );

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

my $device =
	Conch::Model::Device->create( 'coffee', $hardware_product_id );
my $device_id = $device->id;

new_ok('Conch::Model::DeviceReport');

done_testing();
