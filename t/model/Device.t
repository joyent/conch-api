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

my $device_serial = 'c0ff33';
my $d = $schema->resultset('device')->create({
	id => $device_serial,
	hardware_product_id => $hw_product_id,
	state => 'UNKNOWN',
	health => 'UNKNOWN',
});
$d = Conch::Model::Device->new($d->discard_changes->get_columns);

done_testing();
