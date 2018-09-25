use Mojo::Base -strict;
use Mojo::Util 'monkey_patch';
use Test::More;
use Test::Warnings;
use Data::UUID;
use Conch::UUID 'is_uuid';
use Path::Tiny;
use JSON::Validator;

use Data::Printer;

use Test::Conch::Datacenter;

my $t = Test::Conch::Datacenter->new();

my $uuid = Data::UUID->new;

$t->post_ok(
	"/login" => json => {
		user     => 'conch@conch.joyent.us',
		password => 'conch'
	}
)->status_is(200)->json_schema_is('Login');
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

my $global_ws_id = $t->tx->res->json->[0]{id};
BAIL_OUT("No workspace ID") unless $global_ws_id;

$t->get_ok("/workspace/$global_ws_id")->status_is(200)->json_schema_is('Workspace');

$t->get_ok("/workspace/$global_ws_id/user")->status_is(200)
	->json_schema_is('WorkspaceUsers');

$t->get_ok("/workspace/$global_ws_id/problem")->status_is(200)
	->json_schema_is('Problems');

$t->post_ok(
	"/workspace/$global_ws_id/child" => json => {
		name        => "test",
		description => "also test",
	}
)->status_is(201)->json_schema_is('Workspace');

$t->get_ok("/workspace/$global_ws_id/child")->status_is(200)
	->json_schema_is('Workspaces');

$t->get_ok("/me")->status_is(204)->content_is("");

$t->get_ok("/workspace/$global_ws_id/room")->status_is(200)
	->json_is( '/0/az', "test-region-1a" )->json_schema_is('Rooms');

$t->get_ok("/workspace/$global_ws_id/rack")->status_is(200)
	->json_is( '/test-region-1a/0/name', 'Test Rack', 'Has test datacenter rack' )
	->json_schema_is('WorkspaceRackSummary');

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

	my $report =
		path('t/integration/resource/passing-device-report.json')->slurp_utf8;
	$t->post_ok( '/device/TEST', { 'Content-Type' => 'application/json' }, $report )->status_is(200)
		->json_schema_is( 'ValidationState' );

	$t->get_ok("/workspace/$global_ws_id/problem")->status_is(200)
		->json_schema_is('Problems')
		->json_is('/unlocated/TEST/health', 'PASS', 'device is listed as unlocated');
};

# Set the various timestamps on a device so we can validate them
{
	$t->post_ok('/device/TEST/graduate')->status_is(303);

	$t->post_ok('/device/TEST/triton_reboot')->status_is(303);

	$t->post_ok( '/device/TEST/triton_uuid',
		json => { triton_uuid => $uuid->create_str() } )->status_is(303);

	$t->post_ok('/device/TEST/triton_setup')->status_is(303)
}

$t->get_ok('/device/TEST')->status_is(200)->json_schema_is('DetailedDevice');

$t->post_ok(
	"/workspace/$global_ws_id/rack/$rack_id/layout",
	json => {
		TEST => 1
	}
)->status_is(200);

$t->get_ok("/workspace/$global_ws_id/problem")->status_is(200)
	->json_schema_is('Problems')
	->json_hasnt('/unlocated/TEST', 'device is no longer unlocated');

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

$t->get_ok("/workspace/$global_ws_id/device")->status_is(200)->json_is( '/0/id', 'TEST' )
	->json_schema_is('Devices');

$t->get_ok("/workspace/$global_ws_id/device?active=t")->status_is(200)
	->json_is( '/0/id', 'TEST' )->json_schema_is('Devices');

$t->get_ok("/workspace/$global_ws_id/device?graduated=t")->status_is(200)
	->json_is( '/0/id', 'TEST' )->json_schema_is('Devices');

$t->get_ok("/workspace/$global_ws_id/device?health=pass")->status_is(200)
	->json_is( '/0/id', 'TEST' )->json_schema_is('Devices');

$t->get_ok("/workspace/$global_ws_id/relay")->status_is(200)
	->json_is( '/0/id', 'deadbeef', 'Has relay from reporting device' )
	->json_schema_is('WorkspaceRelays');

$t->get_ok("/workspace/$global_ws_id/relay?active=1")->status_is(200)
	->json_is( '/0/id', 'deadbeef', 'Has active relay' )
	->json_schema_is('WorkspaceRelays');

$t->get_ok("/workspace/$global_ws_id/device?ids_only=1")->status_is(200)
	->json_schema_is( { type => 'array', items => { type => 'string' } } );

$t->get_ok("/hardware_product")->status_is(200)
	->json_schema_is('HardwareProducts');

my $hw_id = $t->tx->res->json->[0]->{id};

$t->get_ok("/hardware_product/$hw_id")->status_is(200)
	->json_schema_is('HardwareProduct');

$t->get_ok("/relay")->status_is(200)->json_schema_is('Relays');

subtest "Validations" => sub {
	$t->get_ok("/validation")->status_is(200)->json_schema_is('Validations');

	my $validation_id = $t->tx->res->json->[0]->{id};

	$t->post_ok( "/validation_plan", json => {
		name => 'test_plan',
		description => 'test plan'
	} )->status_is(303);

	$t->get_ok($t->tx->res->headers->location)->json_schema_is('ValidationPlan');
	my $validation_plan_id = $t->tx->res->json->{id};

	$t->get_ok("/validation_plan")->status_is(200)
		->json_schema_is('ValidationPlans');
	$t->get_ok("/validation_plan/$validation_plan_id")->status_is(200)
		->json_schema_is('ValidationPlan');

	$t->post_ok( "/validation_plan/$validation_plan_id/validation",
		json => { id => $validation_id } )->status_is(204);

	$t->get_ok("/device/TEST/validation_state")->status_is(200)
		->json_schema_is( 'ValidationStatesWithResults' );
};

done_testing();
