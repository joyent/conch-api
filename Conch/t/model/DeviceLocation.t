use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB;
use Mojo::Pg;

use IO::All;

use_ok("Conch::Model::DeviceLocation");

use Data::UUID;

my $pgtmp = mk_tmp_db() or die;
my $pg = Mojo::Pg->new( $pgtmp->uri );
my $uuid = Data::UUID->new;


new_ok('Conch::Model::DeviceLocation');
my $device_loc_model = new_ok("Conch::Model::DeviceLocation", [ pg => $pg ]);

my $attempt = $device_loc_model->lookup('deadbeef');
is($attempt, undef, "Bad loookup returns undef");

my $assign_attempt = $device_loc_model->assign('deadbeef', $uuid->create_str, 20);
is($assign_attempt, undef, "Bad assign returns undef");

my $unassign_attempt = $device_loc_model->unassign('deadbeef');
is($unassign_attempt, 0);


TODO: {
	local $TODO = "DeviceLocation needs datacenters, rooms, and racks";
		
	my $dbh = DBI->connect( $pgtmp->dsn );
	for my $file (io->dir("../sql/test/")->sort->glob("*.sql")) {
		$dbh->do($file->all) or BAIL_OUT("Test SQL load failed");
	}


	fail("Can't test DeviceLocation fully yet");
}


done_testing();

