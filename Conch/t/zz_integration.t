use Mojo::Base -strict;
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
		->status_is( 401, 'No body is bad request' );
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
			},
			"Subworkspace V1 Data Contract"
		);
	};
};

######################
### ROOMS
subtest 'Workspace Rooms' => sub {
	$t->get_ok("/workspace/$id/room")->status_is(200)
		->json_has( '/0', 'Has at least 1 DC room' )
		or die;

	my $room_id = $t->tx->res->json->[0]->{id};

	$t->put_ok( "/workspace/$id/room", json => [$room_id] )
		->status_is( 400, 'Cannot modify GLOBAL' )
		->json_like( '/error' => qr/Cannot modify GLOBAL/ );

	$t->put_ok( "/workspace/$sub_ws/room", json => [$room_id] )
		->status_is( 200, 'Replaced datacenter rooms' )
		->json_is( '/0/id', $room_id );

	$t->get_ok("/workspace/$sub_ws/room")->status_is(200)
		->json_is( '/0/id', $room_id );
	$t->put_ok( "/workspace/$sub_ws/room", json => [] )
		->status_is( 200, 'Remove datacenter rooms' )->json_is( '', [] );

};

my $rack_id;
subtest 'Workspace Racks' => sub {

	note(
"Variance: /rack in v1 returns a hash keyed by datacenter room AZ instead of an array"
	);
	$t->get_ok("/workspace/$id/rack")->status_is(200)
		->json_has( '/test-region-1a/0/id', 'Has test datacenter rack' )
		or die;

	$rack_id = $t->tx->res->json->{'test-region-1a'}->[0]->{id};

	$t->get_ok("/workspace/$id/rack/notauuid")->status_is(400)
		->json_like( '/error', qr/must be a UUID/ );
	$t->get_ok( "/workspace/$id/rack/" . $uuid->create_str() )->status_is(404);

	subtest 'Add rack to workspace' => sub {
		$t->post_ok("/workspace/$sub_ws/rack")
			->status_is( 400, 'Requires request body' )->json_like( '/error', qr// );
		$t->post_ok( "/workspace/$sub_ws/rack", json => { id => $rack_id } )
			->status_is(303)
			->header_like( Location => qr!/workspace/$sub_ws/rack/$rack_id! );
		$t->get_ok("/workspace/$sub_ws/rack")->status_is(200);
		$t->get_ok("/workspace/$sub_ws/rack/$rack_id")->status_is(200);

		subtest 'Cannot modify GLOBAL workspace' => sub {
			$t->post_ok( "/workspace/$id/rack", json => { id => $rack_id } )
				->status_is(400)->json_is( '/error', 'Cannot modify GLOBAL workspace' );
		};
	};

	subtest 'Remove rack from workspace' => sub {
		$t->delete_ok("/workspace/$sub_ws/rack/$rack_id")->status_is(204);
		$t->get_ok("/workspace/$sub_ws/rack/$rack_id")->status_is(404)
			->json_like( '/error', qr/not found/ );

		subtest 'Cannot modify GLOBAL workspace' => sub {
			$t->post_ok( "/workspace/$id/rack", json => { id => $rack_id } )
				->status_is(400)->json_is( '/error', 'Cannot modify GLOBAL workspace' );
		};
	};

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

subtest 'Device Report' => sub {
	my $report = io->file('t/resource/passing-device-report.json')->slurp;
	$t->post_ok( '/device/TEST', $report )->status_is(200)
		->json_is( '/health', 'PASS' );
};

subtest 'Single device' => sub {

	$t->get_ok('/device/TEST')->status_is(200);
	$t->get_ok('/device/nonexistant')->status_is(404)
		->json_like( '/error', qr/not found/ );

	subtest 'Device attributes' => sub {
		$t->post_ok('/device/nonexistant/graduate')->status_is(404);

		$t->post_ok('/device/TEST/graduate')->status_is(303)
			->header_like( Location => qr!/device/TEST$! );

		$t->post_ok('/device/TEST/triton_setup')->status_is(409)
			->json_like( '/error',
			qr/must be marked .+ before it can be .+ set up for Triton/ );

		$t->post_ok('/device/TEST/triton_reboot')->status_is(303)
			->header_like( Location => qr!/device/TEST$! );

		$t->post_ok('/device/TEST/triton_uuid')
			->status_is( 400, 'Request body required' );

		$t->post_ok( '/device/TEST/triton_uuid',
			json => { triton_uuid => 'not a UUID' } )->status_is(400)
			->json_like( '/error', qr/a UUID/ );

		$t->post_ok( '/device/TEST/triton_uuid',
			json => { triton_uuid => $uuid->create_str() } )->status_is(303)
			->header_like( Location => qr!/device/TEST$! );

		$t->post_ok('/device/TEST/triton_setup')->status_is(303)
			->header_like( Location => qr!/device/TEST$! );

		$t->post_ok('/device/TEST/asset_tag')
			->status_is( 400, 'Request body required' );

		$t->post_ok( '/device/TEST/asset_tag',
			json => { asset_tag => 'asset tag' } )->status_is(303)
			->header_like( Location => qr!/device/TEST$! );
	};

	subtest 'Device settings' => sub {
		$t->get_ok('/device/TEST/settings')->status_is(200)->content_is('{}');
		$t->get_ok('/device/TEST/settings/foo')->status_is(404);

		$t->post_ok('/device/TEST/settings')->status_is( 400, 'Requires body' )
			->json_like( '/error', qr/required/ );
		$t->post_ok( '/device/TEST/settings', json => { foo => 'bar' } )
			->status_is(200);
		$t->get_ok('/device/TEST/settings')->status_is(200)
			->json_is( '/foo', 'bar', 'Setting was stored' );

		$t->get_ok('/device/TEST/settings/foo')->status_is(200)
			->json_is( '/foo', 'bar', 'Setting was stored' );

		$t->post_ok( '/device/TEST/settings/fizzle',
			json => { no_match => 'gibbet' } )
			->status_is( 400, 'Fail if parameter and key do not match' );
		$t->post_ok( '/device/TEST/settings/fizzle',
			json => { fizzle => 'gibbet' } )->status_is(200);
		$t->get_ok('/device/TEST/settings/fizzle')->status_is(200)
			->json_is( '/fizzle', 'gibbet' );

		$t->delete_ok('/device/TEST/settings/fizzle')->status_is(204)
			->content_is('');
		$t->get_ok('/device/TEST/settings/fizzle')->status_is(404)
			->json_like( '/error', qr/fizzle/ );
		$t->delete_ok('/device/TEST/settings/fizzle')->status_is(404)
			->json_like( '/error', qr/fizzle/ );
	};

};

subtest 'Assigned device' => sub {
	$t->post_ok(
		"/workspace/$id/rack/$rack_id/layout",
		json => {
			TEST => 1
		}
	)->status_is(200);

	$t->get_ok('/device/TEST/location')->status_is(200);

};

subtest 'Workspace devices' => sub {

	$t->get_ok("/workspace/$id/device")->status_is(200)
		->json_is( '/0/id', 'TEST' );

	$t->get_ok("/workspace/$id/device?graduated=f")->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$id/device?graduated=F")->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$id/device?graduated=t")->status_is(200)
		->json_is( '/0/id', 'TEST' );
	$t->get_ok("/workspace/$id/device?graduated=T")->status_is(200)
		->json_is( '/0/id', 'TEST' );

	$t->get_ok("/workspace/$id/device?health=fail")->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$id/device?health=FAIL")->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$id/device?health=pass")->status_is(200)
		->json_is( '/0/id', 'TEST' );
	$t->get_ok("/workspace/$id/device?health=PASS")->status_is(200)
		->json_is( '/0/id', 'TEST' );

	$t->get_ok("/workspace/$id/device?health=pass&graduated=t")->status_is(200)
		->json_is( '/0/id', 'TEST' );
	$t->get_ok("/workspace/$id/device?health=pass&graduated=f")->status_is(200)
		->json_is( '', [] );

	$t->get_ok("/workspace/$id/device?ids_only=1")->status_is(200)
		->content_is('["TEST"]');
	$t->get_ok("/workspace/$id/device?ids_only=1&health=pass")->status_is(200)
		->content_is('["TEST"]');

	$t->get_ok("/workspace/$id/device?active=t")->status_is(200)
		->json_is( '/0/id', 'TEST' );
	$t->get_ok("/workspace/$id/device?active=t&graduated=t")->status_is(200)
		->json_is( '/0/id', 'TEST' );

	# /device/active redirects to /device so first make sure there is a redirect,
	# then follow it and verify the results
	subtest 'Redirect /workspace/:id/device/active' => sub {
		$t->get_ok("/workspace/$id/device/active")->status_is(302);
		my $temp = $t->ua->max_redirects;
		$t->ua->max_redirects(1);
		$t->get_ok("/workspace/$id/device/active")->status_is(200)
			->json_is( '/0/id', 'TEST' );
		$t->ua->max_redirects($temp);
	};
};

subtest 'Relays' => sub {
	$t->get_ok("/workspace/$id/relay")->status_is(200)
		->json_has( '/0', 'Has at least 1 relay from reporting device' );
};

subtest 'Device location' => sub {
	$t->post_ok('/device/TEST/location')->status_is( 400, 'requires body' )
		->json_like( '/error', qr/rack_unit/ )->json_like( '/error', qr/rack_id/ );

	$t->post_ok( '/device/TEST/location',
		json => { rack_id => $rack_id, rack_unit => 3 } )->status_is(303)
		->header_like( Location => qr!/device/TEST/location$! );

	$t->delete_ok('/device/TEST/location')->status_is(204);
};

subtest 'Hardware Product' => sub {

	$t->get_ok("/hardware_product")->status_is(200)
		->json_has( '/0', 'Response has at least one hardware product' )
		or die;

	my $hw_id = $t->tx->res->json->[0]->{id};

	$t->get_ok("/hardware_product/$hw_id")->status_is(200)
		->json_is( '/id', $hw_id );
	$t->get_ok('/hardware_product/notauuid')->status_is(400);
	$t->get_ok( '/hardware_product/' . $uuid->create_str )->status_is(404);
};

subtest 'Log out' => sub {
	$t->post_ok("/logout")->status_is(204);
	$t->get_ok("/workspace")->status_is(401);
};

done_testing();
