use strict;
use warnings;
use utf8;

use Test::Mojo;
use Test::More;
use Data::UUID;
use IO::All;

use Data::Printer;

BEGIN {
	use_ok("Test::ConchTmpDB");
	use_ok( "Conch::Route", qw(all_routes) );
}

my $uuid = Data::UUID->new;

my $pgtmp = mk_tmp_db() or BAIL_OUT("failed to create test database");
my $dbh = DBI->connect( $pgtmp->dsn );

my $t = Test::Mojo->new(
	Conch => {
		pg      => $pgtmp->uri,
		secrets => ["********"]
	}
);

all_routes( $t->app->routes );

$t->get_ok("/ping")->status_is(200)->json_is( '/status' => 'ok' );
$t->get_ok("/version")->status_is(200);

$t->get_ok("/me")->status_is(401)->json_is( '/error' => 'unauthorized' );
$t->get_ok("/login")->status_is(401)->json_is( '/error' => 'unauthorized' );

$t->post_ok(
	"/login" => json => {
		user     => 'conch',
		password => 'conch'
	}
)->status_is(200);
BAIL_OUT("Login failed") if $t->tx->res->code != 200;

isa_ok( $t->tx->res->cookie('conch'), 'Mojo::Cookie::Response' );

subtest 'User' => sub {
	$t->get_ok("/me")->status_is(204)->content_is("");
	$t->get_ok("/user/me/settings")->status_is(200)->json_is( '', {} );
	$t->get_ok("/user/me/settings/BAD")->status_is(404)->json_is(
		'',
		{
			error => "No such setting 'BAD'",
		}
	);
	$t->post_ok(
		"/user/me/settings/TEST" => json => {
			"NOTTEST" => "test",
		}
		)->status_is(400)->json_is(
		{
			error =>
				"Setting key in request object must match name in the URL ('TEST')",
		}
		);

	$t->post_ok(
		"/user/me/settings/TEST" => json => {
			"TEST" => "test",
		}
	)->status_is(200)->content_is('');

	$t->get_ok("/user/me/settings/TEST")->status_is(200)->json_is(
		'',
		{
			"TEST" => "test",
		}
	);

	$t->get_ok("/user/me/settings")->status_is(200)->json_is(
		'',
		{
			"TEST" => "test"
		}
	);

	$t->post_ok(
		"/user/me/settings/TEST2" => json => {
			"TEST2" => "test",
		}
	)->status_is(200)->content_is('');

	$t->get_ok("/user/me/settings/TEST2")->status_is(200)->json_is(
		'',
		{
			"TEST2" => "test",
		}
	);

	$t->get_ok("/user/me/settings")->status_is(200)->json_is(
		'',
		{
			"TEST"  => "test",
			"TEST2" => "test",
		}
	);

	$t->delete_ok("/user/me/settings/TEST")->status_is(204)->content_is('');
	$t->get_ok("/user/me/settings")->status_is(200)->json_is(
		'',
		{
			"TEST2" => "test",
		}
	);

	$t->delete_ok("/user/me/settings/TEST2")->status_is(204)->content_is('');

	$t->get_ok("/user/me/settings")->status_is(200)->json_is( '', {} );
	$t->get_ok("/user/me/settings/TEST")->status_is(404)->json_is(
		'',
		{
			error => "No such setting 'TEST'",
		}
	);

	$t->post_ok(
		"/user/me/settings/dot.setting" => json => {
			"dot.setting" => "set",
		}
	)->status_is(200)->content_is('');

	$t->get_ok("/user/me/settings/dot.setting")->status_is(200)->json_is(
		'',
		{
			"dot.setting" => "set",
		}
	);
	$t->delete_ok("/user/me/settings/dot.setting")->status_is(204)
		->content_is('');

};

my $id;
subtest 'Workspaces' => sub {

	$t->get_ok("/workspace/notauuid")->status_is(400)
		->json_like( '/error', qr/must be a UUID/ );

	$t->get_ok('/workspace')->status_is(200)->json_is( '/0/name', 'GLOBAL' );

	$id = $t->tx->res->json->[0]{id};
	BAIL_OUT("No workspace ID") unless $id;

	$t->get_ok("/workspace/$id")->status_is(200);
	$t->json_is(
		'',
		{
			id          => $id,
			name        => "GLOBAL",
			role        => "Administrator",
			description => "Global workspace. Ancestor of all workspaces.",
			parent_id   => undef,
		},
		'Workspace v1 data contract'
	);

	$t->get_ok( "/workspace/" . $uuid->create_str() )->status_is(404);

	$t->get_ok("/workspace/$id/problem")->status_is(200)->json_is(
		'',
		{
			failing    => {},
			unlocated  => {},
			unreported => {},
		},
		"Workspace Problem (empty) V1 Data Contract"
	);

	$t->get_ok("/workspace/$id/user")->status_is(200);
	$t->json_is(
		'',
		[
			{
				name  => "conch",
				email => 'conch@conch.joyent.us',
				role  => "Administrator",
			}
		],
		"Workspace User v1 Data Contract"
	);

};

my $sub_ws;
subtest 'Sub-Workspace' => sub {

	$t->get_ok("/workspace/$id/child")->status_is(200)->json_is( '', [] );
	$t->post_ok("/workspace/$id/child")
		->status_is( 400, 'No body is bad request' );
	$t->post_ok(
		"/workspace/$id/child" => json => {
			name        => "test",
			description => "also test",
		}
	)->status_is(201);

	$sub_ws = $t->tx->res->json->{id};
	subtest "Sub-workspace" => sub {
		$t->get_ok("/workspace/$id/child")->status_is(200);
		$t->json_is(
			'',
			[
				{
					id          => $sub_ws,
					name        => "test",
					role        => "Administrator",
					description => "also test",
					parent_id   => $id,
				}
			],
			"Subworkspace List V1 Data Contract"
		);

		$t->get_ok("/workspace/$sub_ws")->status_is(200);
		$t->json_is(
			'',
			{
				id          => $sub_ws,
				name        => "test",
				role        => "Administrator",
				description => "also test",
				parent_id   => $id,
			},
			"Subworkspace V1 Data Contract"
		);
	};
};

subtest 'Workspace Rooms' => sub {
	$t->get_ok("/workspace/$id/room")->status_is(200)
		->json_is( '', [], 'No datacenter rooms available' );
};

subtest 'Workspace Racks' => sub {

	note(
"Variance: /rack in v1 returns a hash keyed by datacenter room AZ instead of an array"
	);
	$t->get_ok("/workspace/$id/rack")->status_is(200)
		->json_is( '', {}, 'No racks available' );
};

subtest 'Register relay' => sub {
	$t->post_ok(
		'/relay/deadbeef/register',
		json => {
			serial   => 'deadbeef',
			version  => '0.0.1',
			idaddr   => '127.0.0.1',
			ssh_port => '22',
			alias    => 'test relay'
		}
	)->status_is(204);
};

subtest 'Relay List' => sub {
	$t->get_ok('/relay')->status_is(200)->json_is( '/0/id' => 'deadbeef' )
		->json_is( '/0/version', '0.0.1' );
	subtest 'Update relay' => sub {

		$t->post_ok(
			'/relay/deadbeef/register',
			json => {
				serial   => 'deadbeef',
				version  => '0.0.2',
				idaddr   => '127.0.0.1',
				ssh_port => '22',
				alias    => 'test relay'
			}
		)->status_is(204);

		$t->get_ok('/relay')->status_is(200)->json_is( '/0/id', 'deadbeef' )
			->json_is( '/0/version', '0.0.2', 'Version updated' );
	};
};

subtest 'Device Report' => sub {
	my $report =
		io->file('t/integration/resource/passing-device-report.json')->slurp;
	$t->post_ok( '/device/TEST', { 'Content-Type' => 'application/json' }, $report )->status_is(409)
		->json_like( '/error', qr/Hardware Product '.+' does not exist/ );

	$t->post_ok( '/device/TEST', json => { serial_number => 'TEST' } )
		->status_is(400)->json_like( '/error', qr/Missing property/ );
};

subtest 'Single device' => sub {
	$t->get_ok('/device/TEST')->status_is(404);
};

subtest 'Workspace devices' => sub {

	$t->get_ok("/workspace/$id/device")->status_is(200)->json_is( '', [] );

	$t->get_ok("/workspace/$id/device?graduated=f")->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$id/device?graduated=F")->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$id/device?graduated=t")->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$id/device?graduated=T")->status_is(200)
		->json_is( '', [] );

	$t->get_ok("/workspace/$id/device?health=fail")->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$id/device?health=FAIL")->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$id/device?health=pass")->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$id/device?health=PASS")->status_is(200)
		->json_is( '', [] );

	$t->get_ok("/workspace/$id/device?health=pass&graduated=t")->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$id/device?health=pass&graduated=f")->status_is(200)
		->json_is( '', [] );

	$t->get_ok("/workspace/$id/device?ids_only=1")->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$id/device?ids_only=1&health=pass")->status_is(200)
		->json_is( '', [] );

	$t->get_ok("/workspace/$id/device?active=t")->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$id/device?active=t&graduated=t")->status_is(200)
		->json_is( '', [] );

	# /device/active redirects to /device so first make sure there is a redirect,
	# then follow it and verify the results
	subtest 'Redirect /workspace/:id/device/active' => sub {
		$t->get_ok("/workspace/$id/device/active")->status_is(302);
		my $temp = $t->ua->max_redirects;
		$t->ua->max_redirects(1);
		$t->get_ok("/workspace/$id/device/active")->status_is(200)
			->json_is( '', [] );
		$t->ua->max_redirects($temp);
	};
};

subtest 'Relays' => sub {
	$t->get_ok("/workspace/$id/relay")->status_is(200)
		->json_is( '', [], 'No reporting relays' );
};

subtest 'Hardware Product' => sub {
	$t->get_ok("/hardware_product")->status_is(200)
		->json_is( '', [], 'No hardware products loaded' );
};

subtest 'Log out' => sub {
	$t->post_ok("/logout")->status_is(204);
	$t->get_ok("/workspace")->status_is(401)
		->json_is( '/error' => 'unauthorized' );
};

subtest 'JWT authentication' => sub {
	$t->post_ok(
		"/login" => json => {
			user     => 'conch',
			password => 'conch'
		}
	)->status_is(200)->json_has('/jwt_token');

	my $jwt_token = $t->tx->res->json->{jwt_token};
	my $jwt_sig   = $t->tx->res->cookie('jwt_sig')->value;

	$t->get_ok( "/workspace", { Authorization => "Bearer $jwt_token" } )
		->status_is( 200,
		"user can provide JWT token with cookie to authenticate" );
	$t->reset_session;
	$t->get_ok( "/workspace", { Authorization => "Bearer $jwt_token.$jwt_sig" } )
		->status_is( 200,
		"user can provide Authentication header with full JWT to authenticate" );

	$t->post_ok( '/refresh_token',
		{ Authorization => "Bearer $jwt_token.$jwt_sig" } )->status_is(200)
		->json_has('/jwt_token');

	my $new_jwt_token = $t->tx->res->json->{jwt_token};
	$t->get_ok( "/workspace", { Authorization => "Bearer $new_jwt_token" } )
		->status_is( 200, "Can authenticate with new token" );
	$t->get_ok( "/workspace", { Authorization => "Bearer $jwt_token.$jwt_sig" } )
		->status_is( 401, "Cannot use old token" );
	$t->post_ok( '/refresh_token',
		{ Authorization => "Bearer $jwt_token.$jwt_sig" } )
		->status_is( 401, "Cannot reuse token with old JWT" );

	$t->post_ok(
		'/user/email=conch@conch.joyent.us/revoke',
		{ Authorization => "Bearer $new_jwt_token" }
	)->status_is( 204, "Revoke all tokens for user" );
	$t->get_ok( "/workspace", { Authorization => "Bearer $new_jwt_token" } )
		->status_is( 401, "Cannot use after user revocation" );
	$t->post_ok( '/refresh_token', { Authorization => "Bearer $new_jwt_token" } )
		->status_is( 401, "Cannot after user revocation" );

	$t->post_ok(
		"/login" => json => {
			user     => 'conch',
			password => 'conch'
		}
	)->status_is(200);
	my $jwt_token_2 = $t->tx->res->json->{jwt_token};
	$t->post_ok(
		'/user/me/revoke',
		{ Authorization => "Bearer $jwt_token_2" }
	)->status_is( 204, "Revoke tokens for self" );
	$t->get_ok( "/workspace", { Authorization => "Bearer $jwt_token_2" } )
		->status_is( 401, "Cannot use after self revocation" );
};

done_testing();
