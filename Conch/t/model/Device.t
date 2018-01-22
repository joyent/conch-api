use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use_ok("Conch::Model::Workspace");
use_ok("Conch::Model::Device");

use Data::UUID;

my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new( $pgtmp->uri );

my $uuid = Data::UUID->new;

my $ws_model = new_ok("Conch::Model::Workspace", [ pg => $pg ]);
my $global_ws = $ws_model->lookup_by_name('GLOBAL')->value;

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

new_ok('Conch::Model::Device');
my $device_model = new_ok("Conch::Model::Device", [ pg => $pg ]);

my $new_device_id;
subtest "Create new device" => sub {
  my $device_serial = 'c0ff33';
  my $attempt = $device_model->create( $device_serial, $hardware_product_id );
  isa_ok( $attempt, 'Attempt::Success' );
  is( $attempt->value, $device_serial );
  $new_device_id = $attempt->value;

  my $duplicate_attempt =
    $device_model->create( $device_serial, $hardware_product_id );
  isa_ok( $duplicate_attempt, 'Attempt::Fail' );
  like($duplicate_attempt->failure, qr/duplicate/);
};

my $new_device;
subtest "lookup device " => sub {
  my $attempt = $device_model->lookup( $new_device_id);
  isa_ok( $attempt, 'Attempt::Success' );
  isa_ok( $attempt->value, 'Conch::Class::Device' );
  $new_device = $attempt->value;

  my $bad_attempt = $device_model->lookup( 'bad device id' );
  isa_ok( $bad_attempt, 'Attempt::Fail' );
};

subtest "lookup device in user workspaces" => sub {
  my $attempt =
    Conch::Model::Device::_lookup_device_in_user_workspaces( $pg->db,
    $uuid->create_str(), $new_device_id );
  isa_ok( $attempt, 'Attempt::Fail' );
};

subtest "lookup unlocated device" => sub {
  my $attempt =
    Conch::Model::Device::_lookup_unlocated_device_reported_by_user_relay(
      $pg->db, $uuid->create_str(), $new_device_id );
  isa_ok( $attempt, 'Attempt::Fail' );
};

subtest "device modifiers" => sub {
  my $device;
  $device = $device_model->lookup($new_device_id)->value;

  ok( !defined($device->graduated) );
  $device_model->graduate_device($new_device_id);
  $device = $device_model->lookup($new_device_id)->value;
  ok( defined($device->graduated) );

  ok( !defined($device->triton_setup) );
  $device_model->set_triton_setup($new_device_id);
  $device = $device_model->lookup($new_device_id)->value;
  ok( defined($device->triton_setup) );

  ok( !defined($device->triton_uuid) );
  $device_model->set_triton_uuid($new_device_id, $uuid->create_str());
  $device = $device_model->lookup($new_device_id)->value;
  ok( defined($device->triton_uuid) );

  ok( !defined($device->latest_triton_reboot) );
  $device_model->set_triton_reboot($new_device_id);
  $device = $device_model->lookup($new_device_id)->value;
  ok( defined($device->latest_triton_reboot) );

  ok( !defined($device->asset_tag) );
  $device_model->set_asset_tag($new_device_id, 'asset tag');
  $device = $device_model->lookup($new_device_id)->value;
  is($device->asset_tag, 'asset tag' );

};

done_testing();
