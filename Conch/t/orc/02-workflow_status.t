
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

use Conch::Model::Device;

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
my $hw_product_id = $pg->db->insert(
	'hardware_product',
	{
		name   => 'test hw product',
		alias  => 'alias',
		vendor => $hardware_vendor_id
	},
	{ returning => ['id'] }
)->hash->{id};

my $d = Conch::Model::Device->create( 'c0ff33', $hw_product_id );


throws_ok {
	Conch::Orc::Workflow::Status->new(
		workflow_id => $uuid->create_str(),
		device_id   => $d->id,
	)->save();
} 'Mojo::Exception', 'Status->save with unknown workflow id';


my $w;
lives_ok {
	$w = Conch::Orc::Workflow->new(
		name        => 'sungo',
	)->save();
} 'Workflow->save';

throws_ok {
	Conch::Orc::Workflow::Status->new(
		workflow_id => $w->id,
		device_id   => 'wat',
	)->save();
} 'Mojo::Exception', 'Status->save with unknown device id';

my $s;
lives_ok {
	$s = Conch::Orc::Workflow::Status->new(
		workflow_id => $w->id,
		device_id => $d->id,
	)->save();
} 'Status->save';

my $s2; 
lives_ok {
	$s2 = Conch::Orc::Workflow::Status->from_id($s->id);
} 'Status->from_id';

is_deeply($s->v1, $s2->v1, 'Data fetched cmp data stored');

done_testing();
