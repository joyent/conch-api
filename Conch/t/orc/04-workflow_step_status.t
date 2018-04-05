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

my $d = Conch::Model::Device->create( 'c0ff33', $hardware_product_id );

my $v_id = Conch::Model::ValidationPlan->create("test", "test plan")->id;

my $w;
lives_ok {
	$w = Conch::Orc::Workflow->new(
		name  => 'sungo',
		product_id => $hardware_product_id,
	)->save();
} 'Workflow->save';

my $step;
lives_ok {
	$step = Conch::Orc::Workflow::Step->new(
		name               => 'sungo',
		workflow_id        => $w->id,
		validation_plan_id => $v_id,
		order              => 1,
	)->save();
} 'Step->save with known workflow id';

throws_ok {
	Conch::Orc::Workflow::Step::Status->new(
		device_id            => $d->id,
		workflow_step_id     => $uuid->create_str(),
	)->save();
} 'Mojo::Exception', '->save with bad workflow step id';

throws_ok {
	Conch::Orc::Workflow::Step::Status->new(
		device_id            => 'wat',
		workflow_step_id     => $step->id,
	)->save();
} 'Mojo::Exception', '->save with bad device id';


my $s;
lives_ok {
	$s = Conch::Orc::Workflow::Step::Status->new(
		device_id            => $d->id,
		workflow_step_id     => $step->id,
	)->save();
} '->save';

my $s2;
lives_ok {
	$s2 = Conch::Orc::Workflow::Step::Status->from_id($s->id);
} '->from_id';

is_deeply($s->TO_JSON, $s2->TO_JSON, 'Data stored cmp data fetched');


done_testing();
