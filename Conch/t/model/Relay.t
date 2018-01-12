use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use Conch::Model::Device;
use Conch::Model::Relay;
use Conch::Model::User;

use Data::Printer;
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
my $relay_model = Conch::Model::Relay->new(
    pg => $pg,
  );

my $relay_serial = 'deadbeef';
can_ok($relay_model, 'create');
ok($relay_model->create($relay_serial, 'v1', '127.0.0.1', 22, 'test'));

subtest "connect device relay" => sub {
  my $device_model = Conch::Model::Device->new( pg => $pg );
  my $device_id = $device_model->create( 'coffee', $hardware_product_id )->value;

  ok($relay_model->connect_device_relay($device_id, $relay_serial));
  ok(!$relay_model->connect_device_relay($device_id, 'bad_serial'));
};

subtest "connect user relay" => sub {
  my $user_model = Conch::Model::User->new(
      hash_password => sub { reverse shift },
      pg => $pg,
      validate_against_hash => sub { reverse(shift) eq shift }
    );
  my $user_id = $user_model->create('foo@bar.com', 'password')->value->id;
  ok($relay_model->connect_user_relay($user_id, $relay_serial));
  ok(!$relay_model->connect_user_relay($user_id, 'bad_serial'));
};



done_testing();
