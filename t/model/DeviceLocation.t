use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB qw(mk_tmp_db);

use_ok("Conch::Model::DeviceLocation");

use Data::UUID;
use Conch::Pg;

my $pgtmp = mk_tmp_db();
$pgtmp or die;

my $pg    = Conch::Pg->new( $pgtmp->uri );
my $uuid  = Data::UUID->new;

new_ok('Conch::Model::DeviceLocation');
my $device_loc_model = new_ok( "Conch::Model::DeviceLocation");

my $attempt = $device_loc_model->lookup('deadbeef');
is( $attempt, undef, "Bad loookup returns undef" );

my $assign_attempt =
	$device_loc_model->assign( 'deadbeef', $uuid->create_str, 20 );
is( $assign_attempt, undef, "Bad assign returns undef" );

my $unassign_attempt = $device_loc_model->unassign('deadbeef');
is( $unassign_attempt, 0 );

TODO: {
	local $TODO = "DeviceLocation needs datacenters, rooms, and racks";

	fail("Can't test DeviceLocation fully yet");
}

done_testing();

