use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB qw(mk_tmp_db);
use Mojo::Pg;

use_ok("Conch::Model::Device");
use_ok("Conch::Model::DeviceSettings");

use Conch::Pg;

my $pgtmp = mk_tmp_db() or die;
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

new_ok('Conch::Model::DeviceSettings');

my $device_settings_model = Conch::Model::DeviceSettings->new();

my $settings = { foo => 'bar' };

subtest 'set device settings' => sub {
	my $set_attempt =
		$device_settings_model->set_settings( $device_id, $settings );
	is( $set_attempt, 1, 'set device settings successful' );
};

subtest 'get device settings' => sub {
	my $device_settings = $device_settings_model->get_settings($device_id);
	is_deeply( $device_settings, $settings, 'stored settings match stored' );
};

subtest 'update device setting' => sub {
	$settings->{foo} = 'baz';
	my $next_attempt =
		$device_settings_model->set_settings( $device_id, $settings );
	is( $next_attempt, 1, 'set device settings successful' );

	my $device_settings = $device_settings_model->get_settings($device_id);
	is_deeply( $device_settings, $settings, 'stored settings match' );
};

subtest 'delete device setting' => sub {
	delete $settings->{foo};
	my $deleted =
		$device_settings_model->delete_device_setting( $device_id, 'foo' );
	ok( $deleted, 'Deleted stored setting' );

	my $device_settings = $device_settings_model->get_settings($device_id);
	is_deeply( $device_settings, $settings, 'stored settings match' );
};

done_testing();
