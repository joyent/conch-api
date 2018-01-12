use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use Conch::Model::Device;
use Conch::Model::DeviceSettings;
use Data::Printer;


my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new($pgtmp->uri);

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

my $device_model = Conch::Model::Device->new( pg => $pg );

my $device = $device_model->create( 'coffee', $hardware_product_id );
my $device_id = $device->value;

new_ok('Conch::Model::DeviceSettings');

my $device_settings_model = Conch::Model::DeviceSettings->new(
    pg => $pg,
  );

can_ok($device_settings_model, 'set_settings');

my $settings = { foo => 'bar' };

subtest 'set device settings' => sub {
  my $set_attempt = $device_settings_model->set_settings($device_id, $settings);
  ok($set_attempt->is_success, 'set device settings successful');
};

subtest 'get device settings' => sub {
  can_ok($device_settings_model, 'get_settings');
  my $device_settings = $device_settings_model->get_settings($device_id);
  is_deeply($device_settings, $settings, 'stored settings match stored');
};

subtest 'update device setting' => sub {
  $settings->{foo} = 'baz';
  my $next_attempt = $device_settings_model->set_settings($device_id, $settings);
  ok($next_attempt->is_success, 'set device settings successful');

  my $device_settings = $device_settings_model->get_settings($device_id);
  is_deeply($device_settings, $settings, 'stored settings match');
};

subtest 'delete device setting' => sub {
  can_ok($device_settings_model, 'delete_device_setting');
  delete $settings->{foo};
  my $deleted = $device_settings_model->delete_device_setting($device_id, 'foo');
  ok($deleted, 'Deleted stored setting');

  my $device_settings = $device_settings_model->get_settings($device_id);
  is_deeply($device_settings, $settings, 'stored settings match');
};

done_testing();
