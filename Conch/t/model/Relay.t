use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use_ok("Conch::Model::Device");
use_ok("Conch::Model::Relay");
use_ok("Conch::Model::User");

use Data::UUID;

my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new( $pgtmp->uri );

my $uuid = Data::UUID->new;

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

new_ok('Conch::Model::Relay');
my $relay_model = new_ok("Conch::Model::Relay", [
    pg => $pg,
]);

my $relay_serial = 'deadbeef';
ok($relay_model->create($relay_serial, 'v1', '127.0.0.1', 22, 'test'));

subtest "connect device relay" => sub {
  my $device_model = new_ok("Conch::Model::Device", [ pg => $pg ]);

  my $device_id = Conch::Model::Device->create(
    $pg,
    'coffee',
    $hardware_product_id
  )->id;

  ok($relay_model->connect_device_relay($device_id, $relay_serial));
  ok(!$relay_model->connect_device_relay($device_id, 'bad_serial'));
};

subtest "connect user relay" => sub {

  my $user_id = Conch::Model::User->create($pg, 'foo@bar.com', 'password')->id;
  ok($relay_model->connect_user_relay($user_id, $relay_serial));
  ok(!$relay_model->connect_user_relay($user_id, 'bad_serial'));
};



done_testing();
