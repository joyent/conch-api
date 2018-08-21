use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB qw(mk_tmp_db);
use DDP;
use Data::UUID;
use Conch::Pg;

use_ok("Conch::Model::ValidationResult");

my $uuid  = Data::UUID->new;
my $pgtmp = mk_tmp_db();
$pgtmp or die;
my $pg    = Conch::Pg->new( $pgtmp->uri );

use Test::Conch;
my $t = Test::Conch->new(pg => $pgtmp);

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
		hardware_vendor_id => $hardware_vendor_id
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

my $validation =
	$t->app->db_validations->create({
		name => 'test',
		version => 1,
		description => 'test validation',
		module => 'Test::Validation',
	});

my $result;
subtest "validation result new " => sub {
	$result = Conch::Model::ValidationResult->new(
		device_id           => $device->id,
		validation_id       => $validation->id,
		hardware_product_id => $hardware_product_id,
		message             => 'foobar',
		category            => 'TEST',
		status              => 'fail',
		result_order        => 0
	);
	isa_ok( $result, 'Conch::Model::ValidationResult' );
	ok( !defined( $result->id ) );
};

done_testing();
