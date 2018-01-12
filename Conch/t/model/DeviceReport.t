use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mock::Quick;
use Mojo::Pg;

use Conch::Model::Device;
use Conch::Model::DeviceReport;
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

new_ok('Conch::Model::DeviceReport');

my $device_report_model = Conch::Model::DeviceReport->new(
    pg => $pg,
    log => qobj()
  );

subtest 'add reboot count' => sub {
  Conch::Model::DeviceReport::_add_reboot_count($pg->db, $device_id);
  my $reboot_count = $pg->db->select('device_settings', ['value'], { name => 'reboot_count', device_id => $device_id })->hash->{value};
  is($reboot_count, 0, '_add_reboot_count begins with 0');
  Conch::Model::DeviceReport::_add_reboot_count($pg->db, $device_id);
  $reboot_count = $pg->db->select('device_settings', ['value'], { name => 'reboot_count', device_id => $device_id })->hash->{value};
  is($reboot_count, 1, '_add_reboot_count adds 1');
};

done_testing();
