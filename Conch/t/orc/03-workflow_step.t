
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
	)->save();
} 'Workflow->save';

my $v_id = lc $uuid->create_str();

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
	$s->serialize, 
	$s2->serialize,
	"Saved data matches retrieved from_id data"
);

lives_ok {
	$s2 = Conch::Orc::Workflow::Step->from_name($s->name);
} 'Step->from_name';

is_deeply(
	$s->serialize,
	$s2->serialize,
	"Saved data matches retrieved from_id data"
);

is_deeply($w->serialize, $s->workflow->serialize, "->workflow");

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
