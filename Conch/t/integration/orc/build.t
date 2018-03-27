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

my $spec_file = "json-schema/v1.yaml";
BAIL_OUT("OpenAPI spec file '$spec_file' doesn't exist.")
	unless io->file($spec_file)->exists;


my $pgtmp = mk_tmp_db() or BAIL_OUT("failed to create test database");
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

my $db = Conch::Pg->new->db;

$t->post_ok(
	"/login" => json => {
		user     => 'conch',
		password => 'conch'
	}
)->status_is(200);
BAIL_OUT("Login failed") if $t->tx->res->code != 200;
isa_ok( $t->tx->res->cookie('conch'), 'Mojo::Cookie::Response' );

sub BASE() { "/o" }

##########################

$t->get_ok(BASE."/workflow")->status_is(200)->json_is([]);

$t->post_ok(BASE."/workflow", json => { id => 'wat' });
$t->status_is(400)->json_schema_is("Error");

$t->post_ok(BASE."/workflow", json => {
	name => 'sungo',
	product_id => $hardware_product_id,
})->status_is(303);

$t->get_ok($t->tx->res->headers->location)->json_is(
	'/locked' => 0,
)->json_is(
	'/version' => 1,
)->json_schema_is("Workflow");

my $wid = $t->tx->res->json->{id};

$t->get_ok(BASE."/workflow/".$wid)->status_is(200)->json_is(
	'/id' => $wid
)->json_is(
	'/name' => 'sungo'
)->json_schema_is('Workflow');

$t->post_ok(BASE."/workflow/".$wid, json => {
	locked => 1
})->status_is(303);

$t->get_ok($t->tx->res->headers->location)->json_schema_is("Workflow");


$t->get_ok(BASE."/workflow/".$wid)->status_is(200)->json_is(
	'/locked' => 1,
)->json_is(
	'/name' => 'sungo'
)->json_schema_is('Workflow');

$t->get_ok(BASE."/workflow/".$wid."/delete")->status_is(204);

$t->get_ok(BASE."/workflow/".$wid)->status_is(404)->json_schema_is("Error");

##########################


subtest "Step" => sub {
	$t->post_ok(BASE."/workflow", json => {
		product_id => $hardware_product_id,
		name => 'sungo2'
	})->status_is(303);
	$t->get_ok($t->tx->res->headers->location)->json_schema_is("Workflow");

	$wid = $t->tx->res->json->{id};

	$t->post_ok(BASE."/workflow/$wid/step", json => {
		name => "step 1",
		validation_plan_id => $validation_id,
	})->status_is(303);
	$t->get_ok($t->tx->res->headers->location)->json_schema_is("WorkflowStep");

	my $id = $t->tx->res->json->{id};

	$t->get_ok(BASE."/step/$id")->status_is(200)->json_is(
		'/id' => $id
	)->json_is(
		'/name' => "step 1"
	)->json_is(
		'/order' => 0,
	)->json_schema_is('WorkflowStep');

	$t->post_ok(BASE."/workflow/$wid/step", json => {
		name => "step 2",
		validation_plan_id => $validation_id,
	})->status_is(303);
	$t->get_ok($t->tx->res->headers->location)->json_schema_is("WorkflowStep");

	my $id2 = $t->tx->res->json->{id};

	$t->get_ok(BASE."/step/$id2")->status_is(200)->json_is(
		'/id' => $id2
	)->json_is(
		'/name' => "step 2"
	)->json_is(
		'/order' => 1,
	)->json_schema_is('WorkflowStep');


	$t->delete_ok(BASE."/step/$id")->status_is(204);

	$t->get_ok(BASE."/step/$id2")->status_is(200)->json_is(
		'/id' => $id2
	)->json_is(
		'/name' => "step 2"
	)->json_is(
		'/order' => 0,
	)->json_schema_is('WorkflowStep');


	$t->get_ok(BASE."/step/$id")->status_is(200)->json_schema_is('WorkflowStep');
	isnt($t->tx->res->json->{deactivated}, undef);
  
	$t->post_ok(BASE."/step/$id2", json => {
		retry => 1
	})->status_is(303);
	$t->get_ok($t->tx->res->headers->location)->json_is(
		'/id' => $id2,
	)->json_is(
		'/retry' => 1
	)->json_schema_is('WorkflowStep');

	$t->get_ok(BASE."/step/$id2")->status_is(200)->json_is(
		'/retry' => 1,
	)->json_schema_is('WorkflowStep');

};

##########################

$t->post_ok("/logout")->status_is(204);
done_testing();
