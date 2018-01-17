use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use Conch::Model::DeviceLocation;

use Data::Printer;
use Data::UUID;

my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new( $pgtmp->uri );
my $uuid = Data::UUID->new;

# Really phoning these tests in. They need datacenters, datacenter rooms, and
# datacenter racks to be set up. These tests should be improved as this
# functionality is added -- Lane
# TODO
fail("Can't test DeviceLocation fully yet");


new_ok('Conch::Model::DeviceLocation');
my $device_loc_model = Conch::Model::DeviceLocation->new( pg => $pg );

can_ok($device_loc_model, 'lookup');

my $attempt = $device_loc_model->lookup('deadbeef');
isa_ok($attempt, 'Attempt::Fail');

can_ok($device_loc_model, 'assign');
my $assign_attempt = $device_loc_model->assign('deadbeef', $uuid->create_str, 20);
isa_ok($assign_attempt  , 'Attempt::Fail');

can_ok($device_loc_model, 'unassign');
my $unassign_attempt = $device_loc_model->unassign('deadbeef');
is($unassign_attempt, 0);

done_testing();

