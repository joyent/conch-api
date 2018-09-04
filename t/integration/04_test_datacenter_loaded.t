use Mojo::Base -strict;
use Test::More;
use Data::UUID;
use IO::All;
use Test::Deep;
use Mojo::JSON 'decode_json';

use Test::Conch::Datacenter;

my $t = Test::Conch::Datacenter->new();

my $uuid = Data::UUID->new;

$t->get_ok("/ping")->status_is(200)->json_is( '/status' => 'ok' );
$t->get_ok("/version")->status_is(200);

$t->post_ok(
	"/login" => json => {
		user     => 'conch',
		password => 'conch'
	}
)->status_is(200);
BAIL_OUT("Login failed") if $t->tx->res->code != 200;

isa_ok( $t->tx->res->cookie('conch'), 'Mojo::Cookie::Response' );

$t->get_ok('/workspace')->status_is(200)->json_is( '/0/name', 'GLOBAL' );
my $id = $t->tx->res->json->[0]{id};
BAIL_OUT("No workspace ID") unless $id;

$t->post_ok(
	"/workspace/$id/child" => json => {
		name        => "test",
		description => "also test",
	}
)->status_is(201);

my $sub_ws = $t->tx->res->json->{id};
BAIL_OUT("Could not create sub-workspace.") unless $sub_ws;

subtest 'Workspace Rooms' => sub {

	$t->get_ok("/workspace/$id/room")->status_is(200)
		->json_is( '/0/az', "test-region-1a" );

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
"Variance: /rack in returns a hash keyed by datacenter room AZ instead of an array"
	);
	$t->get_ok("/workspace/$id/rack")->status_is(200)
		->json_is( '/test-region-1a/0/name', 'Test Rack',
		'Has test datacenter rack' );

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
		$t->get_ok("/workspace/$sub_ws/rack/$rack_id")
			->status_is(200)
			->json_schema_is('WorkspaceRack');

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
	my $report =
		io->file('t/integration/resource/passing-device-report.json')->slurp;
	$t->post_ok( '/device/TEST', { 'Content-Type' => 'application/json' }, $report )->status_is(200)
		->json_is( '/status', 'pass' );

	my $device = $t->app->db_devices->find($t->tx->res->json->{device_id});
	cmp_deeply(
		decode_json($device->latest_report->report),
		decode_json($report),
		'json blob stored in the db matches report on disk',
	);
};

subtest 'Single device' => sub {

	$t->get_ok('/device/nonexistant')->status_is(404)
		->json_like( '/error', qr/not found/ );

	$t->get_ok('/device/TEST')->status_is(200)
		->json_schema_is('DetailedDevice');

	my $device_id = $t->tx->res->json->{id};
	my @macs = map { $_->{mac} } $t->tx->res->json->{nics}->@*;

	$t->get_ok('/device/nonexistant')->status_is(404)
		->json_like( '/error', qr/not found/ );

	subtest 'get by device attributes' => sub {
		$t->get_ok("/device?mac=$macs[0]")->status_is(200)
			->json_is( '/id', $device_id, 'got device by mac');

		# device_nics->[2]->device_nic_state has ipaddr' => '172.17.0.173'.
		$t->get_ok("/device?ipaddr=172.17.0.173")->status_is(200)
			->json_is( '/id', $device_id, 'got device by ipaddr');
	};

	subtest 'mutate device attributes' => sub {
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

		$t->post_ok('/device/TEST/validated')->status_is(303)
			->header_like( Location => qr!/device/TEST$! );
		$t->post_ok('/device/TEST/validated')->status_is(204)
			->content_is('');
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

		$t->post_ok( '/device/TEST/settings/foo.bar',
			json => { 'foo.bar' => 'bar' } )->status_is(200);
		$t->get_ok('/device/TEST/settings/foo.bar')->status_is(200)
			->json_is( '/foo.bar', 'bar', 'Setting was stored' );
		$t->delete_ok('/device/TEST/settings/foo.bar')->status_is(204)
			->content_is('');
		$t->get_ok('/device/TEST/settings/foo.bar')->status_is(404)
			->json_like( '/error', qr/foo\.bar/ );
	};

	subtest 'Device Roles And Services' => sub {
		$t->get_ok("/hardware_product")->status_is(200);
		my @hardware_products = $t->tx->res->json->@*;

		$t->get_ok("/device/role")->status_is(200)->json_is([]);
		$t->post_ok("/device/role", json => {
			name => "test",
			hardware_product_id => $hardware_products[0]->{id},
		})->status_is(303);
		$t->get_ok($t->tx->res->headers->location)->status_is(200);

		my $d_role = Conch::Model::DeviceRole->from_id($t->tx->res->json->{id});

		$t->get_ok("/device/role")->status_is(200)->json_is([
			$d_role->TO_JSON
		]);

		########
		
		$t->get_ok("/device/service")->status_is(200)->json_is([]);

		$t->post_ok("/device/service", json => {
			name => "test"
		})->status_is(303);
		$t->get_ok($t->tx->res->headers->location)->status_is(200);

		my $s = Conch::Model::DeviceService->from_id($t->tx->res->json->{id});
	
		$t->get_ok("/device/service")->status_is(200)->json_is([
			$s->TO_JSON
		]);
	
		$t->get_ok('/device/service/'.$s->id)->status_is(200);
		is_deeply($t->tx->res->json, $s->TO_JSON);

		$t->get_ok('/device/service/name='.$s->name)->status_is(200);
		is_deeply($t->tx->res->json, $s->TO_JSON);

		$t->get_ok('/device/service/name=wat')->status_is(404);

		########
		
		$t->post_ok('/device/role/'.$d_role->id.'/add_service', json => {
			service => $s->id
		})->status_is(303);
		$t->get_ok($t->tx->res->headers->location)->status_is(200);
		is_deeply(
			Conch::Model::DeviceRole->from_id($d_role->id)->services,
			[ $s->id ],
		);
		$t->post_ok('/device/role/'.$d_role->id.'/remove_service', json => {
			service => $s->id
		})->status_is(303);
		$t->get_ok($t->tx->res->headers->location)->status_is(200);
		is_deeply(
			Conch::Model::DeviceRole->from_id($d_role->id)->services,
			[ ],
		);
		########
		
		$t->delete_ok('/device/service/'.$s->id)->status_is(204);
		$t->get_ok('/device/service/'.$s->id)->status_is(404);

		$t->delete_ok('/device/role/'.$d_role->id)->status_is(204);
		$t->get_ok('/device/role/'.$d_role->id)->status_is(404);

		########

		$t->post_ok("/device/role", json => {
			hardware_product_id => $hardware_products[0]->{id},
		})->status_is(303);
		$t->get_ok($t->tx->res->headers->location)->status_is(200);
		$d_role = Conch::Model::DeviceRole->from_id($t->tx->res->json->{id});


		$t->get_ok('/device/role/'.$d_role->id)->status_is(200);
		is_deeply($t->tx->res->json, $d_role->TO_JSON);

		$t->get_ok('/device/TEST/role')->status_is(409);

		$t->post_ok('/device/TEST/role', json => {
			role => $d_role->id
		})->status_is(303);

		$t->get_ok($t->tx->res->headers->location)->status_is(200)
			->json_is('/role' => $d_role->id);

		$t->get_ok('/device/TEST/role')->status_is(303);

		$t->get_ok($t->tx->res->headers->location)->status_is(200)
			->json_is('/id' => $d_role->id);
		is_deeply($t->tx->res->json, $d_role->TO_JSON);
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
		->json_is( '/0/id', 'deadbeef', 'Has relay from reporting device' )
		->json_is( '/0/devices/0/id', 'TEST', 'Associated with reporting device' );
	$t->get_ok("/workspace/$id/relay?active=1")->status_is(200)
		->json_is( '/0/id', 'deadbeef', 'Has active relay' );

	$t->get_ok('/relay')->status_is(200)->json_is( '/0/id' => 'deadbeef' );

	$t->get_ok("/workspace/$id/relay?no_devices=0")->status_is(200)
		->json_is( '/0/id', 'deadbeef', 'Has relay from reporting device' )
		->json_is( '/0/devices/0/id', 'TEST', 'Associated with reporting device' );

	$t->get_ok("/workspace/$id/relay?no_devices=1")->status_is(200)
		->json_is( '/0/id', 'deadbeef' )
		->json_is( '/0/devices', [] )

};

subtest 'Validations' => sub {
	$t->get_ok("/validation")->status_is(200);

	my $validation_id = $t->tx->res->json->[0]->{id};

	$t->post_ok( "/validation_plan",
		json => { name => 'test_plan', description => 'test plan' } )
		->status_is(303);

	$t->get_ok($t->tx->res->headers->location)->status_is(200);

	my $validation_plan_id = $t->tx->res->json->{id};

	$t->post_ok( "/validation_plan",
		json => { name => 'test_plan', description => 'test plan' } )
		->status_is(409)
		->json_like( '/error' => qr/already exists with the name 'test_plan'/ );

	$t->get_ok("/validation_plan")->status_is(200);

	$t->get_ok("/validation_plan/$validation_plan_id")->status_is(200);

	$t->post_ok( "/validation_plan/$validation_plan_id/validation",
		json => { id => $validation_id } )->status_is(204);

	$t->get_ok("/validation_plan/$validation_plan_id/validation")->status_is(200);

	$t->get_ok("/validation_plan/$validation_plan_id/validation")->status_is(200)
		->json_is( '/0/id' => $validation_id );

	subtest 'test validating a device' => sub {
		$t->post_ok( "/device/TEST/validation/$validation_id", json => {} )
			->status_is(200);

		$t->post_ok( "/device/TEST/validation_plan/$validation_plan_id",
			json => {} )->status_is(200);
	};

	$t->delete_ok(
		"/validation_plan/$validation_plan_id/validation/$validation_id")
		->status_is(204);

	$t->get_ok("/validation_plan/$validation_plan_id/validation")->status_is(200)
		->content_is('[]');

	$t->get_ok("/device/TEST/validation_state")->status_is(200)
		->json_is( '/0/status', 'pass' );
	$t->get_ok("/device/TEST/validation_state?status=pass")->status_is(200)
		->json_is( '/0/status', 'pass' );
	$t->get_ok("/device/TEST/validation_state?status=fail")->status_is(200)
		->content_is( '[]' );
	$t->get_ok("/device/TEST/validation_state?status=pass,bar")->status_is(400)
		->json_like( '/error', qr/query parameter must be any of/ );

	$t->get_ok("/workspace/$id/validation_state")->status_is(200)
		->json_is( '/0/status', 'pass' );
	$t->get_ok("/workspace/$id/validation_state?status=fail")->status_is(200)
		->content_is( '[]' );
	$t->get_ok("/workspace/$id/validation_state?status=fail,pass,error")->status_is(200)
		->json_is( '/0/status', 'pass' );
	$t->get_ok("/workspace/$id/validation_state?status=pass,bar")->status_is(400)
		->json_like( '/error', qr/query parameter must be any of/ );
};

subtest 'Device location' => sub {
	$t->post_ok('/device/TEST/location')->status_is( 400, 'requires body' )
		->json_like( '/error', qr/rack_unit/ )->json_like( '/error', qr/rack_id/ );

	$t->post_ok( '/device/TEST/location',
		json => { rack_id => $rack_id, rack_unit => 3 } )->status_is(303)
		->header_like( Location => qr!/device/TEST/location$! );

	$t->delete_ok('/device/TEST/location')->status_is(204, 'can delete device location');
};

subtest 'Log out' => sub {
	$t->post_ok("/logout")->status_is(204);
	$t->get_ok("/workspace")->status_is(401);
};

subtest 'Permissions' => sub {
	my $ro_name = 'wat';
	my $ro_email = 'readonly@wat.wat';
	my $ro_pass = 'password';

	subtest "Read-only" => sub {

		my $ro_user = $t->app->db_user_accounts->create({
			name => $ro_name,
			email => $ro_email,
			password => $ro_pass,
			user_workspace_roles => [{
				workspace_id => $id,
				role => 'ro',
			}],
		});

		$t->post_ok(
			"/login" => json => {
				user     => $ro_name,
				password => $ro_pass,
			}
		)->status_is(200);
		BAIL_OUT("Login failed") if $t->tx->res->code != 200;

		$t->get_ok('/workspace')->status_is(200)->json_is( '/0/name', 'GLOBAL' );

		subtest "Can't create a subworkspace" => sub {
			$t->post_ok(
				"/workspace/$id/child" => json => {
					name        => "test",
					description => "also test",
				}
			)->status_is(403)->json_is( "/error", "Forbidden" );
		};

		subtest "Can't add a rack" => sub {
			$t->post_ok( "/workspace/$id/rack", json => { id => $rack_id } )
				->status_is(403)->json_is( "/error", "Forbidden" );
		};

		subtest "Can't set a rack layout" => sub {
			$t->post_ok(
				"/workspace/$id/rack/$rack_id/layout",
				json => {
					TEST => 1
				}
			)->status_is(403)->json_is( "/error", "Forbidden" );
		};

		subtest "Can't invite a user" => sub {
			$t->post_ok(
				"/workspace/$id/user",
				json => {
					user => 'another@wat.wat',
					role => 'ro',
				}
			)->status_is(403)->json_is( "/error", "Forbidden" );
		};

		subtest "Can't get a relay list" => sub {
			$t->get_ok("/relay")->status_is(403);
		};

		$t->get_ok("/workspace/$id/user")
			->status_is(200, 'get list of users for this workspace')
			->json_is([
				{
					name => 'conch',
					email => 'conch@conch.joyent.us',
					role => 'admin',
				},
				{
					name => $ro_name,
					email => $ro_email,
					role => 'ro',
				},
			]);

		$t->post_ok("/logout")->status_is(204);
	};

	subtest "Integrator" => sub {
		my $name = 'integrator';
		my $email = 'integrator@wat.wat';
		my $pass = 'password';

		my $user = $t->app->db_user_accounts->create({
			name => $name,
			email => $email,
			password => $pass,
			user_workspace_roles => [{
				workspace_id => $id,
				role => 'rw',
			}],
		});

		$t->post_ok(
			"/login" => json => {
				user     => $email,
				password => $pass,
			}
		)->status_is(200);

		$t->get_ok('/workspace')->status_is(200)->json_is( '/0/name', 'GLOBAL' );
		subtest "Can't create a subworkspace" => sub {
			$t->post_ok(
				"/workspace/$id/child" => json => {
					name        => "test",
					description => "also test",
				}
			)->status_is(403)->json_is( "/error", "Forbidden" );
		};

		subtest "Can't invite a user" => sub {
			$t->post_ok(
				"/workspace/$id/user",
				json => {
					user => 'another@wat.wat',
					role => 'ro',
				}
			)->status_is(403)->json_is( "/error", "Forbidden" );
		};

		subtest "Can't get a relay list" => sub {
			$t->get_ok("/relay")->status_is(403);
		};

		$t->get_ok("/workspace/$id/user")
			->status_is(200, 'get list of users for this workspace')
			->json_is([
				{
					name => 'conch',
					email => 'conch@conch.joyent.us',
					role => 'admin',
				},
				{
					name => $ro_name,
					email => $ro_email,
					role => 'ro',
				},
				{
					name => $name,
					email => $email,
					role => 'rw',
				},
			]);

		$t->post_ok("/logout")->status_is(204);
	};

};

done_testing();
