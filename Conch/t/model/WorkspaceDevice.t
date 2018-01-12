use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use Conch::Model::WorkspaceDevice;

use Data::UUID;
use Data::Printer;

my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new( $pgtmp->uri );

my $uuid = Data::UUID->new;

new_ok('Conch::Model::WorkspaceDevice');

my $device_model = Conch::Model::WorkspaceDevice->new( pg => $pg );

subtest "Get list of workspace devices" => sub {
  can_ok($device_model, 'list');
  my $devices = $device_model->list($uuid->create_str);
  isa_ok($devices, 'ARRAY');
};


done_testing();

