use Mojo::Base -strict;
use Test::More;
use Test::Exception;

use Test::ConchTmpDB;
use Mojo::Pg;

use Try::Tiny;
use IO::All;
use Data::UUID;

use Conch::Pg;

use Conch::Models;
use Conch::Orc;

use DDP;

my $pgtmp = Test::ConchTmpDB->make_full_db 
	or BAIL_OUT("Couldn't create temp db");
my $dbh = DBI->connect( $pgtmp->dsn );
my $pg = Conch::Pg->new( $pgtmp->uri );


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


my $w = Conch::Orc::Workflow->new(
	name => 'sungo',
	product_id => $hardware_product_id,
)->save();

my $w2 = Conch::Orc::Workflow->new(
	name => 'sungo2',
	product_id => $hardware_product_id,
)->save();

my $w3 = Conch::Orc::Workflow->new(
	name => 'sungo3',
	product_id => $hardware_product_id,
)->save();

my $w4 = Conch::Orc::Workflow->new(
	name => 'sungo4',
	product_id => $hardware_product_id,
)->save();


my $r = Conch::Model::DeviceRole->new(
	hardware_product_id => $hardware_product_id
)->save;


my $l;
lives_ok {
	$l = Conch::Orc::Lifecycle->new(
		name => 'sungo',
		role_id => $r->id,
	)->save;
} "->new->save";


lives_ok {
	$l->append_workflow($w->id);
} "->append_workflow";

is_deeply($l->plan, [ $w->id ], "Plan matches expectations");

##
lives_ok {
	$l->append_workflow($w2->id);
} "->append_workflow";

is_deeply($l->plan, [ $w->id, $w2->id ], "Plan matches expectations");

##
lives_ok {
	$l->remove_workflow($w->id);
} "->remove_workflow";

is_deeply($l->plan, [ $w2->id ], "Plan matches expectations");

##
lives_ok {
	$l->append_workflow($w->id);
} "->append_workflow";

is_deeply($l->plan, [ $w2->id, $w->id ], "Plan matches expectations");

##
lives_ok {
	$l->append_workflow($w2->id);
} "->append_workflow";

is_deeply($l->plan, [ $w2->id, $w->id ], "Plan matches expectations");

##
lives_ok {
	$l->append_workflow($w3->id);
} "->append_workflow";

is_deeply($l->plan, [ $w2->id, $w->id, $w3->id ], "Plan matches expectations");

##
lives_ok {
	$l->remove_workflow($w->id);
} "->remove_workflow";

is_deeply($l->plan, [ $w2->id, $w3->id ], "Plan matches expectations");

##
lives_ok {
	$l->add_workflow($w4->id, 1);
} "->add_workflow";

is_deeply($l->plan, [ $w2->id, $w4->id, $w3->id ], "Plan matches expectations");



done_testing();
