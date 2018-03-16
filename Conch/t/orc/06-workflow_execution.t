
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

my $v_id = lc $uuid->create_str();
my $vr_id = lc $uuid->create_str();

my $w;
lives_ok {
	$w = Conch::Orc::Workflow->new(
		name        => 'sungo',
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

my $step_status;
lives_ok {
	$step_status = Conch::Orc::Workflow::Step::Status->new(
		device_id            => $d->id,
		workflow_step_id     => $step->id,
		validation_result_id => $vr_id,
	)->save();
} 'Step::Status->save';

my $ws;
lives_ok {
	$ws = Conch::Orc::Workflow::Status->new(
		workflow_id => $w->id,
		device_id => $d->id,
	)->save();
} 'Workflow::Status->save';


my $we;
lives_ok {
	$we = Conch::Orc::Workflow::Execution->new(
		workflow_id => $w->id, 
		device_id => $d->id,
	);
} 'Execution->new';

is_deeply($d, $we->device, "->device check");
is_deeply($w, $we->workflow, "->workflow check");


subtest "->v2" => sub {
	my $v2 = $we->v2;
	is_deeply($v2->{steps_status}, [ $step_status ], "->{steps_status}");
	is_deeply($v2->{workflow}, $w->v2_cascade, '->{workflow}');
	is_deeply($v2->{device}, $d->as_v1, '->{device}');
	is_deeply($v2->{status}, [ $ws ], '->{status}');
};

subtest "->v2_latest" => sub {
	my $v2 = $we->v2_latest;
	is_deeply($v2->{steps_status}, [ $step_status ], "->{steps_status}");
	is_deeply($v2->{workflow}, $w->v2_cascade, '->{workflow}');
	is_deeply($v2->{device}, $d->as_v1, '->{device}');
	is_deeply($v2->{status}, [ $ws ], '->{status}');
};



done_testing();
