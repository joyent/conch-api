use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use_ok("Conch::Model::DeviceLocation");

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
my $device_loc_model = new_ok("Conch::Model::DeviceLocation", [ pg => $pg ]);

my $attempt = $device_loc_model->lookup('deadbeef');
isa_ok($attempt, 'Attempt::Fail');

my $assign_attempt = $device_loc_model->assign('deadbeef', $uuid->create_str, 20);
isa_ok($assign_attempt  , 'Attempt::Fail');

my $unassign_attempt = $device_loc_model->unassign('deadbeef');
is($unassign_attempt, 0);

done_testing();

