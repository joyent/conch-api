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
use Conch::Models;

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

my $d = Conch::Model::Device->create( 'test', $hardware_product_id );

my $w;
lives_ok {
	$w = Conch::Orc::Workflow->new(
		name  => 'sungo',
	)->save();
} 'Workflow->save';

my $w2;
lives_ok {
	$w2 = Conch::Orc::Workflow->new(
		name  => 'sungo2',
	)->save();
} 'Workflow->save';


my $l;
lives_ok {
	$l = Conch::Orc::Lifecycle->new(
		name => 'sungo',
		device_role => 'test',
		hardware_id => $hardware_product_id,
	)->save;
} '->new->save';

my $l2;
lives_ok {
	$l2 = Conch::Orc::Lifecycle->from_id($l->id);
} '->from_id';

is_deeply($l->v2, $l2->v2, "Saved data matches retrieved data");

lives_ok {
	$l2 = Conch::Orc::Lifecycle->from_name($l->name);
} '->from_name';
is_deeply($l->v2, $l2->v2, "Saved data matches retrieved data");



lives_ok {
	$l->add_workflow($w);
} '->add_workflow';


lives_ok {
	$l->add_workflow($w2);
} '->add_workflow';


my @w;
lives_ok {
	@w = $l->workflows->@*;
} '->workflows';

is_deeply($w[0], $w->id, "First workflow matches");
is_deeply($w[1], $w2->id, "Second workflow matches");

lives_ok {
	$l->remove_workflow($w);
} '->remove_workflow';


lives_ok {
	@w = $l->workflows->@*;
} '->workflows';

is_deeply($w[0], $w2->id, "First workflow matches");
is($w[1], undef, "No other workflows remain");

done_testing();
