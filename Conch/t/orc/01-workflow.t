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


my $w;
lives_ok {
	$w = Conch::Orc::Workflow->new(
		name => 'sungo',
		product_id => $hardware_product_id,
	)->save();
} 'Workflow->save';


my $w2;
lives_ok {
	$w2 = Conch::Orc::Workflow->from_id($w->id);
} 'Workflow->from_id with known id';

is_deeply(
	$w->TO_JSON,
	$w2->TO_JSON,
	"Saved data matches retrieved from_id data"
);

is_deeply($w->steps, [], "No steps");

done_testing();
