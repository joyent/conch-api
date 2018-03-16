use Mojo::Base -strict;
use Test::More;
use Test::Exception;

use Test::ConchTmpDB;
use Mojo::Pg;

use Try::Tiny;
use IO::All;
use Data::UUID;

use Conch::Pg;
use Conch::Orc;

use DDP;

my $pgtmp = Test::ConchTmpDB->make_full_db 
	or BAIL_OUT("Couldn't create temp db");
my $dbh = DBI->connect( $pgtmp->dsn );
my $pg = Conch::Pg->new( $pgtmp->uri );

my $uuid = Data::UUID->new;

my $w;
lives_ok {
	$w = Conch::Orc::Workflow->new(
		name => 'sungo',
	)->save();
} 'Workflow->save';


my $w2;
lives_ok {
	$w2 = Conch::Orc::Workflow->from_id($w->id);
} 'Workflow->from_id with known id';

is_deeply($w->v2, $w2->v2, "Saved data matches retrieved from_id data");

lives_ok {
	$w2 = Conch::Orc::Workflow->from_name($w->name);
} 'Workflow->from_id with known id';

is_deeply($w->v2, $w2->v2, "Saved data matches retrieved from_name data");

is_deeply($w->steps, [], "No steps");

done_testing();
