use Mojo::Base -strict;
use Mojo::Util 'monkey_patch';
use Test::MojoSchema;
use Test::More;
use Data::UUID;
use Data::Validate::UUID 'is_uuid';
use IO::All;
use JSON::Validator;
use YAML::Tiny;

use Data::Printer;

BEGIN {
	use_ok("Test::ConchTmpDB");
	use_ok( "Conch::Route", qw(all_routes) );
}

my $spec_file = "json-schema/v1.yaml";
BAIL_OUT("OpenAPI spec file '$spec_file' doesn't exist.")
	unless io->file($spec_file)->exists;

my $validator = JSON::Validator->new;
$validator->schema( YAML::Tiny->read($spec_file)->[0] );

# add UUID validation
my $valid_formats = $validator->formats;
$valid_formats->{uuid} = \&is_uuid;
$validator->formats($valid_formats);

my $uuid = Data::UUID->new;

my $pgtmp = mk_tmp_db() or BAIL_OUT("failed to create test database");
my $dbh = DBI->connect( $pgtmp->dsn );

my $t = Test::MojoSchema->new(
	Conch => {
		pg      => $pgtmp->uri,
		secrets => ["********"]
	},
);
$t->validator($validator);

#### Load up data
for my $file ( io->dir("../sql/test/")->sort->glob("*.sql") ) {
	$dbh->do( $file->all ) or BAIL_OUT("Test SQL load failed");
}

all_routes( $t->app->routes );

$t->get_ok("/ping")->status_is(200)->json_is( '/status' => 'ok' );

$t->post_ok(
	"/login" => json => {
		user     => 'conch',
		password => 'conch'
	}
)->status_is(200);
BAIL_OUT("Login failed") if $t->tx->res->code != 200;

isa_ok( $t->tx->res->cookie('conch'), 'Mojo::Cookie::Response' );

$t->get_ok("/user/me/settings")->status_is(200)
	->json_schema_is( { type => 'object' } );

$t->post_ok(
	"/user/me/settings/TEST" => json => {
		"TEST" => "test",
	}
)->status_is(200)->content_is('');

$t->get_ok("/user/me/settings")->status_is(200)
	->json_schema_is( { type => 'object' } );

$t->get_ok('/workspace')->status_is(200)->json_schema_is('Workspaces');

my $id = $t->tx->res->json->[0]{id};
BAIL_OUT("No workspace ID") unless $id;

$t->get_ok("/workspace/$id")->status_is(200)->json_schema_is('Workspace');

$t->get_ok("/workspace/$id/user")->status_is(200)
	->json_schema_is('WorkspaceUsers');

$t->get_ok("/workspace/$id/problem")->status_is(200)->json_schema_is('Problem');

$t->post_ok(
	"/workspace/$id/child" => json => {
		name        => "test",
		description => "also test",
	}
)->status_is(201)->json_schema_is('Workspace');

$t->get_ok("/workspace/$id/child")->status_is(200)
	->json_schema_is('Workspaces');

$t->get_ok("/me")->status_is(204)->content_is("");

$t->get_ok("/workspace/$id/room")->status_is(200)
	->json_is( '/0/az', "test-region-1a" )->json_schema_is('Rooms');

$t->get_ok("/workspace/$id/rack")->status_is(200)
	->json_is( '/test-region-1a/0/name', 'Test Rack', 'Has test datacenter rack' )
	->json_schema_is('RackSummary');

my $rack_id = $t->tx->res->json->{'test-region-1a'}->[0]->{id};

subtest 'Set up a test device' => sub {

	$t->post_ok(
		'/relay/deadbeef/register',
		json => {
			serial   => 'deadbeef',
			version  => '0.0.1',
			idaddr   => '127.0.0.1',
			ssh_port => '22',
			alias    => 'test relay'
		}
	)->status_is(204)->content_is('');

	my $report = io->file('t/resource/passing-device-report.json')->slurp;
	$t->post_ok( '/device/TEST', $report )->status_is(200)
		->json_is( '/health', 'PASS' );
};

TODO: {
	local $TODO = q(
	Postgres timestamps are being rendered in JSON response rather than ISO
	8601 formatted timestamps. This causes the date-time format validation to
	fail for the following endpoints.
	);
	$t->get_ok('/device/TEST')->status_is(200)->json_schema_is('DetailedDevice');
}

$t->post_ok(
	"/workspace/$id/rack/$rack_id/layout",
	json => {
		TEST => 1
	}
)->status_is(200);

$t->get_ok('/device/TEST/location')->status_is(200)
	->json_schema_is('DeviceLocation');

$t->get_ok("/device/TEST/settings")->status_is(200)
	->json_schema_is( { type => 'object' } );

$t->post_ok(
	"/device/TEST/settings" => json => {
		"TEST" => "test",
	}
)->status_is(200)->content_is('');

$t->get_ok("/device/TEST/settings")->status_is(200)
	->json_schema_is( { type => 'object' } );

TODO: {
	local $TODO = q(
	Postgres timestamps are being rendered in JSON response rather than ISO
	8601 formatted timestamps. This causes the date-time format validation to
	fail for the following endpoints.
	);
	$t->get_ok("/workspace/$id/device")->status_is(200)
		->json_is( '/0/id', 'TEST' )->json_schema_is('Devices');

	$t->get_ok("/workspace/$id/device?active=t")->status_is(200)
		->json_is( '/0/id', 'TEST' )->json_schema_is('Devices');

	$t->get_ok("/workspace/$id/device?graduated=f")->status_is(200)
		->json_is( '/0/id', 'TEST' )->json_schema_is('Devices');

	$t->get_ok("/workspace/$id/device?health=fail")->status_is(200)
		->json_is( '/0/id', 'TEST' )->json_schema_is('Devices');

	$t->get_ok("/workspace/$id/relay")->status_is(200)
		->json_is( '/0/id', 'deadbeef', 'Has relay from reporting device' )
		->json_schema_is('Relays');
}

$t->get_ok("/workspace/$id/device?ids_only=1")->status_is(200)
	->json_schema_is( { type => 'array', items => { type => 'string' } } );

$t->get_ok("/hardware_product")->status_is(200)
	->json_schema_is('HardwareProducts');

my $hw_id = $t->tx->res->json->[0]->{id};

$t->get_ok("/hardware_product/$hw_id")->status_is(200)
	->json_schema_is('HardwareProduct');

done_testing();
