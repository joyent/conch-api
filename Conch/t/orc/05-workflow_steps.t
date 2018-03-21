
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



throws_ok {
	Conch::Orc::Workflow::Step->new(
		name               => 'sungo',
		workflow_id        => $uuid->create_str(),
		validation_plan_id => $uuid->create_str(),
		order              => 1,
	)->save();
} 'Mojo::Exception', 'Step->save with unknown workflow id';


my $w;
lives_ok {
	$w = Conch::Orc::Workflow->new(
		name        => 'sungo',
		hardware_id => $hardware_product_id,
	)->save();
} 'Workflow->save with known hardware id';

my $v_id = lc $uuid->create_str();

my $s;
lives_ok {
	$s = Conch::Orc::Workflow::Step->new(
		name               => 'sungo',
		workflow_id        => $w->id,
		validation_plan_id => $v_id,
		order              => 1,
	)->save();
} 'Step->save with known workflow id part 1';

is(Conch::Orc::Workflow->from_id($w->id)->steps->@*, 1, "Step count check");

my $s2;
lives_ok {
	Conch::Orc::Workflow::Step->new(
		name               => 'sungo2',
		workflow_id        => $w->id,
		validation_plan_id => $v_id,
		order              => 2,
	)->save();
} 'Step->save with known workflow id part 2';
is(Conch::Orc::Workflow->from_id($w->id)->steps->@*, 2, "Step count check");

my $s3;
lives_ok {
	$s3 = Conch::Orc::Workflow::Step->new(
		name               => 'sungo3',
		workflow_id        => $w->id,
		validation_plan_id => $v_id,
		order              => 3,
	)->save();
} 'Step->save with known workflow id part 3';


is(Conch::Orc::Workflow->from_id($w->id)->steps->@*, 3, "Step count check");

my $s4;
lives_ok {
	$s4 = Conch::Orc::Workflow::Step->new(
		name               => 'sungo4',
		workflow_id        => $w->id,
		validation_plan_id => $v_id,
		order              => 4,
	);

	$w->add_step($s4);
} '->add_step';

is(Conch::Orc::Workflow->from_id($w->id)->steps->@*, 4, "Step count check");

lives_ok {
	$w->remove_step($s3);
} '->remove_step';


my $w2 = Conch::Orc::Workflow->from_id($w->id);
is(scalar $w2->steps->@*, 3, "Step count check");
is($w2->steps_as_objects->[-1]->order, scalar $w2->steps->@*, 'Order verification');


done_testing();
