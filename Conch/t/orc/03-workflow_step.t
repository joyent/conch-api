
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

use Conch::Model::ValidationPlan;

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


my $v_id = Conch::Model::ValidationPlan->create("test", "test plan")->id;


throws_ok {
	Conch::Orc::Workflow::Step->new(
		name               => 'sungo',
		workflow_id        => $uuid->create_str(),
		validation_plan_id => $v_id,
		order              => 1,
	)->save();
} 'Mojo::Exception', 'Step->save with unknown workflow id';


my $w;
lives_ok {
	$w = Conch::Orc::Workflow->new(
		name        => 'sungo',
		product_id  => $hardware_product_id,
	)->save();
} 'Workflow->save';


my $s;
lives_ok {
	$s = Conch::Orc::Workflow::Step->new(
		name               => 'sungo',
		workflow_id        => $w->id,
		validation_plan_id => $v_id,
		order              => 1,
	)->save();
} 'Step->save with known workflow id';

$w->_refresh_steps;


my $s2;
lives_ok {
	$s2 = Conch::Orc::Workflow::Step->from_id($s->id);
} 'Step->from_id with known id';

is_deeply(
	$s->TO_JSON, 
	$s2->TO_JSON,
	"Saved data matches retrieved from_id data"
);

lives_ok {
	$s2 = Conch::Orc::Workflow::Step->from_name($s->name);
} 'Step->from_name';

is_deeply(
	$s->TO_JSON,
	$s2->TO_JSON,
	"Saved data matches retrieved from_id data"
);

is_deeply($w->TO_JSON, $s->workflow->TO_JSON, "->workflow");

my $s3;
lives_ok {
	$s3 = Conch::Orc::Workflow::Step->new(
		name               => 'sungo2',
		workflow_id        => $w->id,
		validation_plan_id => $v_id,
		order              => 2,
	)->save();
} 'Step->save with known workflow id';


done_testing();
