use strict;
use warnings;
use utf8;

use Test::MojoSchema;
use Test::More;
use Test::Exception; 

use IO::All;
use JSON::Validator;
use Data::UUID;
use Data::Validate::UUID 'is_uuid';

BEGIN {
	use_ok("Test::ConchTmpDB");
	use_ok("Conch");
	use_ok("Conch::Route::Orc");
}
use Conch::Pg;

my $spec_file = "json-schema/v2.yaml";
BAIL_OUT("OpenAPI spec file '$spec_file' doesn't exist.")
	unless io->file($spec_file)->exists;


my $pgtmp = mk_tmp_db() or BAIL_OUT("failed to create test database");
my $dbh = DBI->connect( $pgtmp->dsn );

my $t = Test::MojoSchema->new(
	'Conch' => {
		pg      => $pgtmp->uri,
		secrets => ["********"],
		features => { orc => 1 },
	}
);

my $validator = JSON::Validator->new;
$validator->schema( $spec_file );

# add UUID validation
my $valid_formats = $validator->formats;
$valid_formats->{uuid} = \&is_uuid;
$validator->formats($valid_formats);

$t->validator($validator);

# XXX
my $uuid = Data::UUID->new;
my $validation_id = lc $uuid->create_str();


$t->post_ok(
	"/login" => json => {
		user     => 'conch',
		password => 'conch'
	}
)->status_is(200);
BAIL_OUT("Login failed") if $t->tx->res->code != 200;
isa_ok( $t->tx->res->cookie('conch'), 'Mojo::Cookie::Response' );
my $db = Conch::Pg->new->db;

sub BASE() { '/v2/o/humans' }

$t->get_ok(BASE."/workflow")->status_is(200)->json_is([]);
$t->json_schema_is('Workflows');


my ($w, $d, $hw_id);
lives_ok {
	my $hardware_vendor_id = $db->insert(
		'hardware_vendor',
		{ name      => 'test vendor' },
		{ returning => ['id'] }
	)->hash->{id};
	$hw_id = $db->insert(
		'hardware_product',
		{
			name   => 'test hw product',
			alias  => 'alias',
			vendor => $hardware_vendor_id
		},
		{ returning => ['id'] }
	)->hash->{id};

	$w = Conch::Orc::Workflow->new(
		name        => 'sungo',
	)->save();

	$d = Conch::Model::Device->create(
		'orc test',
		$hw_id,
	);

} "Load data";



$t->get_ok(BASE."/workflow")->status_is(200)->json_is(
	'/0/id' => $w->id
)->json_schema_is('Workflows');

$t->get_ok(BASE."/workflow/".$w->id)->status_is(200)->json_is(
	'/id' => $w->id
)->json_schema_is('Workflow');

subtest "Step" => sub {

	my $step;
	lives_ok {
		$step = Conch::Orc::Workflow::Step->new(
			name               => 'sungo',
			workflow_id        => $w->id,
			validation_plan_id => $validation_id,
			order              => 0,
		)->save();
	} 'Load step';


	$t->get_ok(BASE."/workflow")->status_is(200)->json_is(
		'/0/id' => $w->id
	)->json_is(
		'/0/steps/0/id' => $step->id
	)->json_schema_is('Workflows');

	my $step2;
	lives_ok {
		$step2 = Conch::Orc::Workflow::Step->new(
			name               => 'sungo2',
			workflow_id        => $w->id,
			validation_plan_id => $validation_id,
			order              => 1,
		)->save();
	} 'Load another step';

	$t->get_ok(BASE."/step/".$step2->id)->status_is(200)->json_is(
		'/id' => $step2->id
	)->json_is(
		'/name' => $step2->name
	)->json_schema_is('WorkflowStep');

	$t->get_ok(BASE."/workflow")->status_is(200)->json_is(
		'/0/id' => $w->id
	)->json_is(
		'/0/steps/0/id' => $step->id
	)->json_is(
		'/0/steps/1/id' => $step2->id
	)->json_schema_is('Workflows');
};

subtest "Executions" => sub {
	my $s;
	lives_ok {
		$s = Conch::Orc::Workflow::Status->new(
			device_id => $d->id,
			workflow_id => $w->id,
			status => Conch::Orc::Workflow::Status->ONGOING,
		)->save();
	}, "Add an ONGOING workflow status";


	$t->get_ok(BASE."/execution/active")->status_is(200)->json_is(
		'/0/workflow/id' => $w->id,
	)->json_is(
		'/0/status/0/id' => $s->id,
	)->json_is(
		'/0/status/0/status' => Conch::Orc::Workflow::Status->ONGOING
	)->json_schema_is("WorkflowExecutions");


	my $s2;
	lives_ok {
		$s2 = Conch::Orc::Workflow::Status->new(
			device_id => $d->id,
			workflow_id => $w->id,
			status => Conch::Orc::Workflow::Status->STOPPED,
		)->save();
	}, "Add a STOPPED workflow status";

	$t->get_ok(BASE."/execution/stopped")->status_is(200)->json_is(
		'/0/workflow/id' => $w->id,
	)->json_is(
		'/0/status/1/id' => $s2->id,
	)->json_is(
		'/0/status/1/status' => Conch::Orc::Workflow::Status->STOPPED
	)->json_schema_is("WorkflowExecutions");

	$t->get_ok(BASE."/execution/active")->status_is(200)->json_is([]);
	$t->json_schema_is('WorkflowExecutions');

	$t->get_ok(BASE."/device/".$d->id."/execution")->status_is(200)->json_is(
		'/0/workflow/id' => $w->id,
	)->json_is(
		'/0/status/1/id' => $s2->id,
	)->json_is(
		'/0/status/1/status' => Conch::Orc::Workflow::Status->STOPPED
	)->json_schema_is('WorkflowExecutions');


	$t->get_ok(BASE."/device/".$d->id)->status_is(200)->json_is(
		'/workflow/id' => $w->id,
	)->json_is(
		'/status/0/id' => $s2->id,
	)->json_is(
		'/status/0/status' => Conch::Orc::Workflow::Status->STOPPED
	)->json_schema_is('WorkflowExecution');
};

subtest "Lifecycle" => sub {
	my $l;
	lives_ok {
		$l = Conch::Orc::Lifecycle->new(
			name => 'sungo',
			device_role => 'test',
			hardware_id => $hw_id,
		)->save;
	} 'Lifecycle->new->save';

	lives_ok {
		$l->add_workflow($w);
	} 'Lifecycle->add_workflow';


	$t->get_ok(BASE."/lifecycle")->status_is(200)->json_is(
		'/0/id' => $l->id
	)->json_is(
		'/0/name' => $l->name
	)->json_schema_is("Lifecycles");

	$t->get_ok(BASE."/lifecycle/".$l->id)->status_is(200)->json_is(
		'/id' => $l->id,
	)->json_is(
		'/name' => $l->name,
	)->json_schema_is("Lifecycle");

	subtest "Device lifecycle" => sub {
		$t->get_ok(BASE."/device/".$d->id."/lifecycle")->status_is(200);
		$t->json_is(
			'/0/id' => $l->id
		)->json_is(
			'/1' => undef
		)->json_schema_is("Lifecycles");


		$t->get_ok(BASE."/device/".$d->id."/lifecycle/execution");
		$t->status_is(200);
		$t->json_is(
			'/0/lifecycle/id' => $l->id
		)->json_is(
			'/0/executions/0/device/id' => $d->id
		)->json_schema_is("LifecyclesWithExecutions");
	};


};

$t->post_ok("/logout")->status_is(204);

done_testing();
