use strict;
use warnings;
use utf8;

use Test::MojoSchema;
use Test::More;
use Test::Exception; 

use IO::All;
use JSON::Validator;
use Data::UUID;
use Conch::UUID 'is_uuid';

BEGIN {
	use_ok("Test::ConchTmpDB");
	use_ok("Conch");
	use_ok("Conch::Route::Orc");
}
use Conch::Pg;

use Conch::Model::ValidationPlan;

my $spec_file = "json-schema/v1.yaml";
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

my $uuid = Data::UUID->new;

my $validation_id = Conch::Model::ValidationPlan->create("test", "test plan")->id;

$t->post_ok(
	"/login" => json => {
		user     => 'conch',
		password => 'conch'
	}
)->status_is(200);
BAIL_OUT("Login failed") if $t->tx->res->code != 200;
isa_ok( $t->tx->res->cookie('conch'), 'Mojo::Cookie::Response' );
my $db = Conch::Pg->new->db;

sub BASE() { '/o' }

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
		product_id  => $hw_id,
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

$t->post_ok(
	BASE."/workflow/".$w->id, 
	json => {
		name => 'sungo-again',
	}
)->status_is(303);
$t->get_ok($t->tx->res->headers->location)->status_is(200)->json_is(
	"/name" => "sungo-again",
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
		'/0/steps/0' => $step->id
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
		'/0/steps/0' => $step->id
	)->json_is(
		'/0/steps/1' => $step2->id
	)->json_schema_is('Workflows');

	$t->post_ok(
		BASE."/step/".$step2->id, 
		json => {
			name => 'sungo-again',
		}
	)->status_is(303);
	$t->get_ok($t->tx->res->headers->location)->status_is(200)->json_is(
		"/name" => "sungo-again",
	)->json_schema_is('WorkflowStep')


};


subtest "Lifecycle" => sub {
	my $w2 = Conch::Orc::Workflow->new(
		name        => 'sungo2',
		product_id  => $hw_id,
	)->save();
	my $w3 = Conch::Orc::Workflow->new(
		name        => 'sungo3',
		product_id  => $hw_id,
	)->save();
	my $w4 = Conch::Orc::Workflow->new(
		name        => 'sungo4',
		product_id  => $hw_id,
	)->save();
	my $r = Conch::Model::DeviceRole->new(
		hardware_product_id => $hw_id
	)->save;


	$t->get_ok(BASE."/lifecycle")->status_is(200)
		->json_schema_is('OrcLifecycles')
		->json_is([]);

	$t->post_ok(BASE."/lifecycle", json => {
		name    => 'sungo',
		role_id => $uuid->create(),
	})->status_is(400);


	$t->post_ok(BASE."/lifecycle", json => {
		name    => 'sungo',
		role_id => $r->id,
	})->status_is(303);
	$t->get_ok($t->tx->res->headers->location)->status_is(200)
		->json_schema_is("OrcLifecycle")
		->json_is( "/name" => "sungo" );


	my $l_id = $t->tx->res->json->{id};

	$t->post_ok(BASE."/lifecycle/$l_id", json => {
		role_id => $uuid->create(),
	})->status_is(400);

	$t->post_ok(BASE."/lifecycle", json => {
		name    => 'dupe role',
		role_id => $r->id,
	})->status_is(400);



	$t->post_ok(BASE."/lifecycle/$l_id", json => {
		name    => 'sungo2',
	})->status_is(303);
	$t->get_ok($t->tx->res->headers->location)->status_is(200)
		->json_schema_is("OrcLifecycle")
		->json_is( "/name" => "sungo2" );


	$t->post_ok(BASE."/lifecycle/${l_id}/add_workflow", json => {
		workflow_id => $w->id,
	})->status_is(303);
	$t->get_ok($t->tx->res->headers->location)->status_is(200)
		->json_schema_is("OrcLifecycle")
		->json_is( "/plan" => [ $w->id ] );


	$t->post_ok(BASE."/lifecycle/${l_id}/add_workflow", json => {
		workflow_id => $w2->id,
	})->status_is(303);
	$t->get_ok($t->tx->res->headers->location)->status_is(200)
		->json_schema_is("OrcLifecycle")
		->json_is( "/plan" => [ $w->id, $w2->id ] );

	$t->post_ok(BASE."/lifecycle/${l_id}/add_workflow", json => {
		workflow_id => $w3->id,
		plan_order => 1,
	})->status_is(303);
	$t->get_ok($t->tx->res->headers->location)->status_is(200)
		->json_schema_is("OrcLifecycle")
		->json_is( "/plan" => [ $w->id, $w3->id, $w2->id ] );


	$t->post_ok(BASE."/lifecycle/${l_id}/remove_workflow", json => {
		workflow_id => $w->id,
	})->status_is(303);
	$t->get_ok($t->tx->res->headers->location)->status_is(200)
		->json_schema_is("OrcLifecycle")
		->json_is( "/plan" => [ $w3->id, $w2->id ] );

};

$t->post_ok("/logout")->status_is(204);

done_testing();
