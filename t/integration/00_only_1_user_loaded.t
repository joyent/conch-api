use strict;
use warnings;
use utf8;

use Test::More;
use Data::UUID;
use Path::Tiny;
use Test::Warnings ':all';
use Test::Conch;
use Test::Deep;
use Test::Memory::Cycle;

my $uuid = Data::UUID->new;

my $t = Test::Conch->new;

$t->get_ok('/ping')->status_is(200)
	->json_is('/status' => 'ok')
	->header_isnt('Request-Id' => undef)
	->header_isnt('X-Request-ID' => undef);

$t->get_ok('/version')
	->status_is(200);

$t->get_ok('/me')->status_is(401)->json_is({ error => 'unauthorized' });
$t->get_ok('/login')->status_is(401)->json_is({ error => 'unauthorized' });

my $now = Conch::Time->now;

$t->post_ok(
	'/login' => json => {
		user     => 'conch@conch.joyent.us',
		password => 'conch'
	}
)->status_is(200);
BAIL_OUT('Login failed') if $t->tx->res->code != 200;

isa_ok( $t->tx->res->cookie('conch'), 'Mojo::Cookie::Response' );

my $conch_user = $t->app->db_user_accounts->find({ name => 'conch' });

ok($conch_user->last_login >= $now, 'user last_login is updated')
	or diag('last_login not updated: ' . $conch_user->last_login . ' is not updated to ' . $now);


subtest 'User' => sub {
	$t->get_ok('/me')
		->status_is(204)
		->content_is('');

	$t->get_ok('/user/me/settings')
		->status_is(200)
		->json_is('', {});

	$t->get_ok('/user/me/settings/BAD')
		->status_is(404)
		->json_is('', { error => "No such setting 'BAD'" });

	$t->post_ok(
		'/user/me/settings/TEST' => json => { 'NOTTEST' => 'test' })
		->status_is(400)
		->json_is({ error => "Setting key in request object must match name in the URL ('TEST')", });

	$t->post_ok('/user/me/settings/TEST' => json => { 'TEST' => 'TEST' })
		->status_is(200)
		->content_is('');

	$t->get_ok('/user/me/settings/TEST')
		->status_is(200)
		->json_is('', { 'TEST' => 'TEST' });

	$t->get_ok('/user/me/settings')
		->status_is(200)
		->json_is('', { 'TEST' => 'TEST' });

	$t->post_ok('/user/me/settings/TEST2' => json => { 'TEST2' => 'test' })
		->status_is(200)
		->content_is('');

	$t->get_ok('/user/me/settings/TEST2')
		->status_is(200)
		->json_is('', { 'TEST2' => 'test' });

	$t->get_ok('/user/me/settings')
		->status_is(200)
		->json_is('', {
			'TEST'  => 'TEST',
			'TEST2' => 'test',
		});

	$t->delete_ok('/user/me/settings/TEST')
		->status_is(204)
		->content_is('');
	$t->get_ok('/user/me/settings')
		->status_is(200)
		->json_is('', { 'TEST2' => 'test' });

	$t->delete_ok('/user/me/settings/TEST2')
		->status_is(204)
		->content_is('');

	$t->get_ok('/user/me/settings')
		->status_is(200)
		->json_is('', {});
	$t->get_ok('/user/me/settings/TEST')
		->status_is(404)
		->json_is('', { error => "No such setting 'TEST'" });

	$t->post_ok('/user/me/settings/dot.setting' => json => { 'dot.setting' => 'set' })
		->status_is(200)
		->content_is('');

	$t->get_ok('/user/me/settings/dot.setting')
		->status_is(200)
		->json_is('', { 'dot.setting' => 'set' });

	$t->delete_ok('/user/me/settings/dot.setting')
		->status_is(204)
		->content_is('');

	# everything should be deactivated now.
	# starting over, let's see if set_settings overwrites everything...

	$t->post_ok('/user/me/settings' => json => { TEST1 => 'TEST', TEST2 => 'ohhai', })
		->status_is(200)
		->content_is('');

	$t->post_ok('/user/me/settings' => json => { TEST1 => 'test1', TEST3 => 'test3', })
		->status_is(200)
		->content_is('');

	$t->get_ok('/user/me/settings')
		->status_is(200)
		->json_is('', {
			TEST1 => 'test1',
			TEST3 => 'test3',
		});

	$t->post_ok('/user/me/password' => json => { password => 'ohhai' })
		->status_is(204, 'changed password');

	$t->get_ok('/user/me/settings')
		->status_is(401, 'session tokens revoked too');

	$t->post_ok(
		'/login' => json => {
			user     => 'conch@conch.joyent.us',
			password => 'conch'
		}
	)->status_is(401, 'cannot use old password after changing it');

	$t->post_ok(
		'/login' => json => {
			user     => 'conch@conch.joyent.us',
			password => 'ohhai'
		}
	)->status_is(200, 'logged in using new password');
	$t->post_ok(
		'/user/me/password' => json => { password => 'conch' }
	)->status_is(204, 'changed password back');

	$t->post_ok(
		'/login' => json => {
			user     => 'conch@conch.joyent.us',
			password => 'conch'
		}
	)->status_is(200, 'logged in using original password');
	$t->get_ok('/user/me/settings')
		->status_is(200, 'original password works again');
};

my $global_ws_id = $t->app->db_workspaces->get_column('id')->single;
my %workspace_data;

subtest 'Workspaces' => sub {

	$t->get_ok('/workspace/notauuid')
		->status_is(400)
		->json_like( '/error', qr/must be a UUID/ );

	$t->get_ok('/workspace')
		->status_is(200)
		->json_schema_is('WorkspacesAndRoles')
		->json_is('', [ {
			id          => $global_ws_id,
			name        => 'GLOBAL',
			role        => 'admin',
			description => 'Global workspace. Ancestor of all workspaces.',
			parent_id   => undef,
		} ]);

	$workspace_data{conch}[0] = $t->tx->res->json->[0];

	$t->get_ok("/workspace/$global_ws_id")
		->status_is(200)
		->json_schema_is('WorkspaceAndRole')
		->json_is('', $workspace_data{conch}[0], 'data for GLOBAL workspace');

	$t->get_ok('/workspace/' . $uuid->create_str())
		->status_is(404);

	$t->get_ok("/workspace/$global_ws_id/user")
		->status_is(200)
		->json_schema_is('WorkspaceUsers')
		->json_cmp_deeply('', [
			{
				id    => ignore,
				name  => 'conch',
				email => 'conch@conch.joyent.us',
				role  => 'admin',
			}
		], 'data for users who can access GLOBAL');

	is($t->app->db_user_workspace_roles->count, 1,
		'currently one user_workspace_role entry');

	$t->post_ok('/user?send_mail=0',
		json => { email => 'test_workspace@conch.joyent.us', name => 'test_workspace', password => '123' })
		->status_is(201, 'created new user test_workspace')
		->json_schema_is('User');

	$t->post_ok("/workspace/$global_ws_id/user?send_mail=0" => json => {
			user => 'test_workspace@conch.joyent.us',
			role => 'rw',
		})
		->status_is(201, 'added the user to the GLOBAL workspace');

	is($t->app->db_user_workspace_roles->count, 2,
		'now there is another user_workspace_role entry');

	is(
		$t->app->db_user_accounts
			->find({ email => 'test_workspace@conch.joyent.us' })
			->search_related('user_workspace_roles', { workspace_id => $global_ws_id })
			->count,
		1,
		'new user can access this workspace',
	);

	$t->post_ok("/workspace/$global_ws_id/user?send_mail=0" => json => {
			user => 'test_workspace@conch.joyent.us',
			role => 'rw',
		})
		->status_is(200, 'redundant add requests do nothing');

	is($t->app->db_user_workspace_roles->count, 2,
		'still just two user_workspace_role entries');

	$t->post_ok("/workspace/$global_ws_id/user?send_mail=0" => json => {
			user => 'test_workspace@conch.joyent.us',
			role => 'ro',
		})
		->status_is(400)
		->json_is({ error => "user test_workspace already has rw access to workspace $global_ws_id: cannot downgrade role to ro" });

	$t->get_ok('/user/email=test_workspace@conch.joyent.us')
		->status_is(200)
		->json_schema_is('UserDetailed')
		->json_is('/email' => 'test_workspace@conch.joyent.us')
		->json_is('/workspaces' => [ {
				id => $global_ws_id,
				name => 'GLOBAL',
				description => 'Global workspace. Ancestor of all workspaces.',
				role => 'rw',
				parent_id => undef,
			} ]);

	$workspace_data{test_workspace} = $t->tx->res->json->{workspaces};

	$t->get_ok('/user/')
		->status_is(200)
		->json_schema_is('UsersDetailed')
		->json_is('/0/email', 'conch@conch.joyent.us')
		->json_is('/0/workspaces' => [ $workspace_data{conch}[0] ])
		->json_is('/1/email', 'test_workspace@conch.joyent.us')
		->json_is('/1/workspaces' => [ $workspace_data{test_workspace}[0] ]);

	my $main_user_id = $t->tx->res->json->[0]{id};
	my $test_user_id = $t->tx->res->json->[1]{id};

	$t->get_ok("/workspace/$global_ws_id/user")
		->status_is(200)
		->json_schema_is('WorkspaceUsers')
		->json_cmp_deeply('', bag(
			{
				id    => $main_user_id,
				name  => 'conch',
				email => 'conch@conch.joyent.us',
				role  => 'admin',
			},
			{
				id    => $test_user_id,
				name  => 'test_workspace',
				email => 'test_workspace@conch.joyent.us',
				role  => 'rw',
			}
		), 'data for users who can access GLOBAL');
};

subtest 'Sub-Workspace' => sub {

	$t->get_ok("/workspace/$global_ws_id/child")
		->status_is(200)
		->json_schema_is('WorkspacesAndRoles')
		->json_is('', []);

	$t->post_ok("/workspace/$global_ws_id/child")
		->status_is(400, 'No body is bad request')
		->json_like('/error', qr/Expected object/);

	$t->post_ok("/workspace/$global_ws_id/child" => json => { name => 'GLOBAL' })
		->status_is(400, 'Cannot create duplicate workspace')
		->json_is('', { error => "workspace 'GLOBAL' already exists" });

	$t->post_ok(
		"/workspace/$global_ws_id/child" => json => {
			name        => "test",
			description => "also test",
		})
		->status_is(201)
		->json_schema_is('WorkspaceAndRole')
		->json_cmp_deeply({
			id          => ignore,
			name        => 'test',
			description => 'also test',
			parent_id   => $global_ws_id,
			role        => 'admin',
			role_via    => $global_ws_id,
		});

	my $sub_ws_id = $t->tx->res->json->{id};
	$workspace_data{conch}[1] = $t->tx->res->json;

	$t->get_ok("/workspace/$global_ws_id/child")
		->status_is(200)
		->json_schema_is('WorkspacesAndRoles')
		->json_is('', [ $workspace_data{conch}[1] ], 'data for workspaces under GLOBAL');

	$t->get_ok("/workspace/$sub_ws_id")
		->status_is(200)
		->json_schema_is('WorkspaceAndRole')
		->json_is('', $workspace_data{conch}[1], 'data for subworkspace');

	$t->post_ok(
		"/workspace/$sub_ws_id/child" => json => {
			name        => 'grandchild',
			description => 'two levels of subworkspaces',
		})->status_is(201, 'created a grandchild workspace')
		->json_schema_is('WorkspaceAndRole')
		->json_cmp_deeply({
			id          => ignore,
			name        => 'grandchild',
			description => 'two levels of subworkspaces',
			parent_id   => $sub_ws_id,
			role        => 'admin',
			role_via    => $global_ws_id,
		});

	my $grandsub_ws_id = $t->tx->res->json->{id};
	$workspace_data{conch}[2] = $t->tx->res->json;

	$t->get_ok("/workspace/$global_ws_id/child")
		->status_is(200)
		->json_schema_is('WorkspacesAndRoles')
		->json_is('', [
				$workspace_data{conch}[1],
				$workspace_data{conch}[2],
			], 'data for workspaces under GLOBAL with recursive query');

	$t->get_ok('/workspace')
		->status_is(200)
		->json_schema_is('WorkspacesAndRoles')
		->json_is('', [
				$workspace_data{conch}[0],
				$workspace_data{conch}[1],
				$workspace_data{conch}[2],
			], 'data for all workspaces with recursive query');

	$t->get_ok('/user/email=conch@conch.joyent.us')
		->status_is(200)
		->json_schema_is('UserDetailed')
		->json_is('/email' => 'conch@conch.joyent.us')
		->json_is('/workspaces' => [
				$workspace_data{conch}[0],
				$workspace_data{conch}[1],
				$workspace_data{conch}[2],
			],
			'main user has access to all workspaces via GLOBAL');

	$t->get_ok('/user/me')
		->status_is(200)
		->json_schema_is('UserDetailed')
		->json_is('/email' => 'conch@conch.joyent.us')
		->json_is('/workspaces' => [
				$workspace_data{conch}[0],
				$workspace_data{conch}[1],
				$workspace_data{conch}[2],
			],
			'/user/me returns the same data');

	$t->get_ok('/user/email=test_workspace@conch.joyent.us')
		->status_is(200)
		->json_schema_is('UserDetailed')
		->json_is('/email' => 'test_workspace@conch.joyent.us')
		->json_is('/workspaces' => [
				{
					id => $global_ws_id,
					name => 'GLOBAL',
					description => 'Global workspace. Ancestor of all workspaces.',
					parent_id => undef,
					role => 'rw',
				},
				{
					id => $sub_ws_id,
					name => 'test',
					description => 'also test',
					parent_id => $global_ws_id,
					role => 'rw',
					role_via => $global_ws_id,
				},
				{
					id => $grandsub_ws_id,
					name => 'grandchild',
					description => 'two levels of subworkspaces',
					parent_id => $sub_ws_id,
					role => 'rw',
					role_via => $global_ws_id,
				},
			],
			'new user has access to all workspaces via GLOBAL');

	$workspace_data{test_workspace} = $t->tx->res->json->{workspaces};

	$t->get_ok('/user')
		->status_is(200, 'data for all users, all workspaces')
		->json_schema_is('UsersDetailed')
		->json_is('/0/email', 'conch@conch.joyent.us')
		->json_is('/0/workspaces' => $workspace_data{conch})
		->json_is('/1/email', 'test_workspace@conch.joyent.us')
		->json_is('/1/workspaces' => $workspace_data{test_workspace});

	my $main_user_id = $t->tx->res->json->[0]{id};
	my $test_user_id = $t->tx->res->json->[1]{id};

	$t->get_ok("/workspace/$sub_ws_id/user")
		->status_is(200)
		->json_schema_is('WorkspaceUsers')
		->json_cmp_deeply('', bag(
			{
				id    => $main_user_id,
				name  => 'conch',
				email => 'conch@conch.joyent.us',
				role  => 'admin',
				role_via => $global_ws_id,
			},
			{
				id    => $test_user_id,
				name  => 'test_workspace',
				email => 'test_workspace@conch.joyent.us',
				role  => 'rw',
				role_via => $global_ws_id,
			},
		), 'data for users who can access subworkspace');

	$t->get_ok("/workspace/$grandsub_ws_id/user")
		->status_is(200)
		->json_schema_is('WorkspaceUsers')
		->json_cmp_deeply('', bag(
			{
				id    => $main_user_id,
				name  => 'conch',
				email => 'conch@conch.joyent.us',
				role  => 'admin',
				role_via => $global_ws_id,
			},
			{
				id    => $test_user_id,
				name  => 'test_workspace',
				email => 'test_workspace@conch.joyent.us',
				role  => 'rw',
				role_via => $global_ws_id,
			},
		), 'data for users who can access grandchild workspace');

	$t->post_ok("/workspace/$grandsub_ws_id/user?send_mail=0" => json => {
			user => 'test_workspace@conch.joyent.us',
			role => 'rw',
		})
		->status_is(200, 'redundant add requests do nothing');

	is($t->app->db_user_workspace_roles->count, 2,
		'still just two user_workspace_role entries');

	$t->post_ok("/workspace/$grandsub_ws_id/user?send_mail=0" => json => {
			user => 'test_workspace@conch.joyent.us',
			role => 'ro',
		})
		->status_is(400)
		->json_is({ error => "user test_workspace already has rw access to workspace $grandsub_ws_id via workspace $global_ws_id: cannot downgrade role to ro" });

	$t->post_ok("/workspace/$grandsub_ws_id/user?send_mail=0" => json => {
			user => 'test_workspace@conch.joyent.us',
			role => 'admin',
		})
		->status_is(201, 'can upgrade existing permission');

	is($t->app->db_user_workspace_roles->count, 3,
		'now there are three user_workspace_role entries');

	# now let's try manipulating permissions on the workspace in the middle of the heirarchy

	$t->post_ok("/workspace/$sub_ws_id/user?send_mail=0" => json => {
			user => 'test_workspace@conch.joyent.us',
			role => 'rw',
		})
		->status_is(200, 'redundant add requests do nothing');

	$t->post_ok("/workspace/$sub_ws_id/user?send_mail=0" => json => {
			user => 'test_workspace@conch.joyent.us',
			role => 'ro',
		})
		->status_is(400)
		->json_is({ error => "user test_workspace already has rw access to workspace $sub_ws_id via workspace $global_ws_id: cannot downgrade role to ro" });

	is($t->app->db_user_workspace_roles->count, 3,
		'still just three user_workspace_role entries');

	$t->post_ok("/workspace/$sub_ws_id/user?send_mail=0" => json => {
			user => 'test_workspace@conch.joyent.us',
			role => 'admin',
		})
		->status_is(201, 'can upgrade existing permission');

	is($t->app->db_user_workspace_roles->count, 4,
		'now there are four user_workspace_role entries');

	# update our idea of what all the permissions should look like:
	$workspace_data{test_workspace}[1]{role} = 'admin';
	delete $workspace_data{test_workspace}[1]{role_via};
	$workspace_data{test_workspace}[2]{role} = 'admin';
	delete $workspace_data{test_workspace}[2]{role_via};

	$t->get_ok('/user/email=conch@conch.joyent.us')
		->status_is(200)
		->json_schema_is('UserDetailed')
		->json_is('/email' => 'conch@conch.joyent.us')
		->json_is('/workspaces' => [
				$workspace_data{conch}[0],
				$workspace_data{conch}[1],
				$workspace_data{conch}[2],
			],
			'main user has access to all workspaces via GLOBAL');

	$t->get_ok('/user/email=test_workspace@conch.joyent.us')
		->status_is(200)
		->json_schema_is('UserDetailed')
		->json_is('/email' => 'test_workspace@conch.joyent.us')
		->json_cmp_deeply('/workspaces' => bag(
				$workspace_data{test_workspace}[0],
				$workspace_data{test_workspace}[1],
				$workspace_data{test_workspace}[2],
			),
			'test user now has direct access to all workspaces');

	$t->get_ok('/user')
		->status_is(200, 'data for all users, all workspaces')
		->json_schema_is('UsersDetailed')
		->json_is('/0/email', 'conch@conch.joyent.us')
		->json_cmp_deeply('/0/workspaces' => bag($workspace_data{conch}->@*))
		->json_is('/1/email', 'test_workspace@conch.joyent.us')
		->json_cmp_deeply('/1/workspaces' => bag($workspace_data{test_workspace}->@*));

	$t->delete_ok("/workspace/$sub_ws_id/user/email=test_workspace\@conch.joyent.us")
		->status_is(201, 'extra permissions for user are removed from the sub workspace and its children');

	$workspace_data{test_workspace}[1]->@{qw(role role_via)} = ('rw', $global_ws_id);
	$workspace_data{test_workspace}[2]->@{qw(role role_via)} = ('rw', $global_ws_id);

	$t->get_ok('/user/email=test_workspace@conch.joyent.us')
		->status_is(200)
		->json_schema_is('UserDetailed')
		->json_is('/email' => 'test_workspace@conch.joyent.us')
		->json_cmp_deeply('/workspaces' => $workspace_data{test_workspace},
			'test user now only has rw access to everything again (via GLOBAL)');

	$t->delete_ok("/workspace/$sub_ws_id/user/email=test_workspace\@conch.joyent.us")
		->status_is(201, 'deleting again is a no-op');
};

subtest 'Workspace Rooms' => sub {
	$t->get_ok("/workspace/$global_ws_id/room")
		->status_is(200)
		->json_schema_is('Rooms')
		->json_is( '', [], 'No datacenter rooms available' );
};

subtest 'Workspace Racks' => sub {

	note(
"Variance: /rack in returns a hash keyed by datacenter room AZ instead of an array"
	);
	$t->get_ok("/workspace/$global_ws_id/rack")
		->status_is(200)
		->json_is('', {}, 'No racks available');
};

subtest 'Relays' => sub {
	$t->post_ok(
		'/relay/deadbeef/register',
		json => {
			serial   => 'deadbeef',
			version  => '0.0.1',
			ipaddr   => '127.0.0.1',
			ssh_port => '22',
			alias    => 'test relay',
		}
	)->status_is(204);

	my $relay = $t->app->db_relays->find('deadbeef');
	cmp_deeply(
		[ $relay->user_relay_connections ],
		[
			methods(
				first_seen => bool(1),
				last_seen => bool(1),
			),
		],
		'user_relay_connection timestamps are set',
	);

	$t->get_ok('/relay')
		->status_is(200)
		->json_schema_is('Relays')
		->json_is([
			{
				id => 'deadbeef',
				version  => '0.0.1',
				ipaddr   => '127.0.0.1',
				ssh_port => '22',
				alias    => 'test relay',
				created  => $relay->created,
				updated  => $relay->updated,
			}
		]);

	$relay->user_relay_connections->update({
		first_seen => '1999-01-01',
		last_seen => '1999-01-01',
	});

	$t->post_ok(
		'/relay/deadbeef/register',
		json => {
			serial   => 'deadbeef',
			version  => '0.0.2',
			ipaddr   => '127.0.0.1',
			ssh_port => '22',
			alias    => 'test relay',
		}
	)->status_is(204);

	$relay->discard_changes;	# reload from db

	$t->get_ok('/relay')
		->status_is(200)
		->json_schema_is('Relays')
		->json_is('', [
			{
				id => 'deadbeef',
				version  => '0.0.2',
				ipaddr   => '127.0.0.1',
				ssh_port => '22',
				alias    => 'test relay',
				created  => $relay->created,
				updated  => $relay->updated,
			}
		], 'version was updated');
	my $y2000 = Conch::Time->new(year=> 2000);
	cmp_ok(($relay->user_relay_connections)[0]->first_seen, '<', $y2000, 'first_seen was not updated');
	cmp_ok(($relay->user_relay_connections)[0]->last_seen, '>', $y2000, 'last_seen was updated');
};

subtest 'Device Report' => sub {
	my $report =
		path('t/integration/resource/passing-device-report.json')->slurp_utf8;
	$t->post_ok( '/device/TEST', { 'Content-Type' => 'application/json' }, $report )
		->status_is(409)
		->json_is({ error => 'Could not locate hardware product' });

	$t->post_ok( '/device/TEST', json => { serial_number => 'TEST' } )
		->status_is(400)->json_like( '/error', qr/Missing property/ );
};

subtest 'Single device' => sub {
	$t->get_ok('/device/TEST')
		->status_is(404);
};

subtest 'Workspace devices' => sub {

	$t->get_ok("/workspace/$global_ws_id/device")
		->status_is(200)
		->json_is('', []);

	$t->get_ok("/workspace/$global_ws_id/device?graduated=f")
		->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$global_ws_id/device?graduated=F")
		->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$global_ws_id/device?graduated=t")
		->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$global_ws_id/device?graduated=T")
		->status_is(200)
		->json_is( '', [] );

	$t->get_ok("/workspace/$global_ws_id/device?health=fail")
		->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$global_ws_id/device?health=FAIL")
		->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$global_ws_id/device?health=pass")
		->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$global_ws_id/device?health=PASS")
		->status_is(200)
		->json_is( '', [] );

	$t->get_ok("/workspace/$global_ws_id/device?health=pass&graduated=t")
		->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$global_ws_id/device?health=pass&graduated=f")
		->status_is(200)
		->json_is( '', [] );

	$t->get_ok("/workspace/$global_ws_id/device?ids_only=1")
		->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$global_ws_id/device?ids_only=1&health=pass")
		->status_is(200)
		->json_is( '', [] );

	$t->get_ok("/workspace/$global_ws_id/device?active=t")
		->status_is(200)
		->json_is( '', [] );
	$t->get_ok("/workspace/$global_ws_id/device?active=t&graduated=t")
		->status_is(200)
		->json_is( '', [] );

	# /device/active redirects to /device so first make sure there is a redirect,
	# then follow it and verify the results
	subtest 'Redirect /workspace/:id/device/active' => sub {
		$t->get_ok("/workspace/$global_ws_id/device/active")
			->status_is(302);
		$t->ua->max_redirects(1);
		$t->get_ok("/workspace/$global_ws_id/device/active")
			->status_is(200)
			->json_is( '', [], 'got empty list of workspaces' );
		$t->ua->max_redirects(0);
	};
};

subtest 'Relays' => sub {
	$t->get_ok("/workspace/$global_ws_id/relay")
		->status_is(200)
		->json_schema_is('WorkspaceRelays')
		->json_is('', [], 'No reporting relays');
};

subtest 'Hardware Product' => sub {
	$t->get_ok("/hardware_product")
		->status_is(200)
		->json_is( '', [], 'No hardware products loaded' );
};

subtest 'Log out' => sub {
	$t->post_ok("/logout")
		->status_is(204);
	$t->get_ok("/workspace")
		->status_is(401)
		->json_is({ error => 'unauthorized' });
};

subtest 'JWT authentication' => sub {
	$t->post_ok(
		"/login" => json => {
			user     => 'conch@conch.joyent.us',
			password => 'conch'
		}
	)->status_is(200)->json_has('/jwt_token');

	my $jwt_token = $t->tx->res->json->{jwt_token};
	my $jwt_sig   = $t->tx->res->cookie('jwt_sig')->value;

	$t->get_ok( "/workspace", { Authorization => "Bearer $jwt_token" } )
		->status_is( 200,
		"user can provide JWT token with cookie to authenticate" );
	$t->reset_session;	# force JWT to be used to authenticate
	$t->get_ok( "/workspace", { Authorization => "Bearer $jwt_token.$jwt_sig" } )
		->status_is( 200,
		"user can provide Authentication header with full JWT to authenticate" );

	$t->post_ok('/refresh_token', { Authorization => "Bearer $jwt_token.$jwt_sig" })
		->status_is(200)
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
			user     => 'conch@conch.joyent.us',
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

subtest 'modify another user' => sub {

	$t->post_ok(
		'/user?send_mail=0',
		json => { name => 'me', email => 'foo@conch.joyent.us' })
		->status_is(400, 'user name "me" is prohibited')
		->json_is({ error => 'user name "me" is prohibited' });

	$t->post_ok(
		'/user?send_mail=0',
		json => { name => 'foo', email => 'conch@conch.joyent.us' })
		->status_is(409, 'cannot create user with a duplicate email address')
		->json_schema_is('UserError')
		->json_is({
				error => 'duplicate user found',
				user => {
					id => $conch_user->id,
					email => 'conch@conch.joyent.us',
					name => 'conch',
					created => $conch_user->created,
					deactivated => undef,
				}
			});

	$t->post_ok(
		'/user?send_mail=0',
		json => { name => 'conch', email => 'CONCH@conch.JOYENT.us' })
		->status_is(409, 'emails are not case sensitive when checking for duplicate users')
		->json_schema_is('UserError')
		->json_is({
				error => 'duplicate user found',
				user => {
					id => $conch_user->id,
					email => 'conch@conch.joyent.us',
					name => 'conch',
					created => $conch_user->created,
					deactivated => undef,
				}
			});

	$t->post_ok(
		'/user?send_mail=0',
		json => { email => 'foo@conch.joyent.us', name => 'foo', password => '123' })
		->status_is(201, 'created new user foo')
		->json_schema_is('User')
		->json_has('/id', 'got user id')
		->json_is('/email' => 'foo@conch.joyent.us', 'got email')
		->json_is('/name' => 'foo', 'got name');

	my $new_user_id = $t->tx->res->json->{id};
	my $new_user = $t->app->db_user_accounts->find($new_user_id);

	$t->get_ok("/user/$new_user_id")
		->status_is(200)
		->json_schema_is('UserDetailed')
		->json_like('/created', qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/, 'timestamp in RFC3339')
		->json_is('', {
			id => $new_user_id,
			name => 'foo',
			email => 'foo@conch.joyent.us',
			created => $new_user->created,
			last_login => undef,
			refuse_session_auth => JSON::PP::false,
			force_password_change => JSON::PP::false,
			is_admin => JSON::PP::false,
			workspaces => [],
		}, 'returned all the right fields (and not the password)');

	my $new_user_data = $t->tx->res->json;

	$t->post_ok(
		'/user?send_mail=0',
		json => { email => 'foo@conch.joyent.us', name => 'foo', password => '123' })
		->status_is(409, 'cannot create the same user again')
		->json_schema_is('UserError')
		->json_is('/error' => 'duplicate user found')
		->json_is('/user/id' => $new_user_id, 'got user id')
		->json_is('/user/email' => 'foo@conch.joyent.us', 'got user email')
		->json_is('/user/name' => 'foo', 'got user name')
		->json_is('/user/deactivated' => undef, 'got user deactivated date');

	$t->post_ok('/user/email=foo@conch.joyent.us' => json => { name => 'FOO', is_admin => 1 })
		->status_is(200)
		->json_schema_is('UserDetailed')
		->json_is('', {
			%$new_user_data,
			name => 'FOO',
			is_admin => JSON::PP::true,
		});

	my $t2 = Test::Conch->new(pg => $t->pg);
	$t2->post_ok(
		'/login' => json => {
			user     => 'foo@conch.joyent.us',
			password => '123'
		})
		->status_is(200, 'new user can log in');
	my $jwt_token = $t2->tx->res->json->{jwt_token};
	my $jwt_sig   = $t2->tx->res->cookie('jwt_sig')->value;

	$t2->get_ok('/me')->status_is(204);

	my $t3 = Test::Conch->new(pg => $t->pg);	# we will only use this $mojo for basic auth
	$t3->get_ok($t3->ua->server->url->userinfo('foo@conch.joyent.us:123')->path('/me'))
		->status_is(204, 'user can also use the app with basic auth');

	$t->post_ok("/user/$new_user_id/revoke")
		->status_is(204, 'revoked all tokens for the new user');

	$t2->get_ok('/me')
		->status_is(401, 'new user cannot authenticate with persistent session after session is cleared')
		->json_is({ error => 'unauthorized' });

	$t2->get_ok('/me', { Authorization => "Bearer $jwt_token.$jwt_sig" })
		->status_is(401, 'new user cannot authenticate with JWT after tokens are revoked')
		->json_is({ error => 'unauthorized' });

	$t2->post_ok(
		'/login' => json => {
			user     => 'foo@conch.joyent.us',
			password => '123'
		})
		->status_is(200, 'new user can still log in again');
	$jwt_token = $t2->tx->res->json->{jwt_token};
	$jwt_sig   = $t2->tx->res->cookie('jwt_sig')->value;

	$t2->get_ok('/me')->status_is(204, 'session token re-established');

	$t2->reset_session;	# force JWT to be used to authenticate
	$t2->get_ok('/me', { Authorization => "Bearer $jwt_token.$jwt_sig" })
		->status_is(204, 'new JWT established');


	# in order to get the user's new password, we need to extract it from a method call before
	# we forget it -- so we pull it out of the call to UserAccount->update.
	my $orig_update = \&Conch::DB::Result::UserAccount::update;
	my $_new_password;
	no warnings 'redefine';
	local *Conch::DB::Result::UserAccount::update = sub {
		$_new_password = $_[1]->{password} if exists $_[1]->{password};
		$orig_update->(@_);
	};

	$t->delete_ok(
		"/user/foobar/password?send_password_reset_mail=0")
		->status_is(404, 'attempted to reset the password for a non-existent user')
		->json_is({ error => "user foobar not found" });

	$t->delete_ok(
		"/user/$new_user_id/password?send_password_reset_mail=0")
		->status_is(204, 'reset the new user\'s password');

	$t->delete_ok(
		'/user/email=FOO@CONCH.JOYENT.US/password?send_password_reset_mail=0')
		->status_is(204, 'reset the new user\'s password again, using (case insensitive) email lookup');
	my $insecure_password = $_new_password;

	$t2->get_ok('/me')
		->status_is(401, 'user can no longer use his saved session after his password is changed')
		->json_is({ error => 'unauthorized' });

	$t2->reset_session;	# force JWT to be used to authenticate
	$t2->get_ok('/me', { Authorization => "Bearer $jwt_token.$jwt_sig" })
		->status_is(401, 'user cannot authenticate with JWT after his password is changed')
		->json_is({ error => 'unauthorized' });

	$t2->post_ok(
		'/login' => json => {
			user     => 'foo@conch.joyent.us',
			password => 'foo',
		})
		->status_is(401, 'cannot log in with the old password')
		->json_is({ 'error' => 'unauthorized' });

	$t3->get_ok($t3->ua->server->url->userinfo('foo@conch.joyent.us:' . $insecure_password)->path('/me'))
		->status_is(401, 'user cannot use new password with basic auth')
		->location_is('/user/me/password')
		->json_is({ error => 'unauthorized' });

	$t2->post_ok(
		'/login' => json => {
			user     => 'foo@conch.joyent.us',
			password => $insecure_password,
		})
		->status_is(200, 'user can log in with new password')
		->location_is('/user/me/password');
	$jwt_token = $t2->tx->res->json->{jwt_token};
	$jwt_sig   = $t2->tx->res->cookie('jwt_sig')->value;
	cmp_ok($t2->tx->res->cookie('jwt_sig')->expires, '<', time + 11 * 60, 'JWT expires in 10 minutes');

	$t2->get_ok('/me')
		->status_is(401, 'user can\'t use his session to do anything else')
		->location_is('/user/me/password')
		->json_is({ error => 'unauthorized' });

	$t2->reset_session;	# force JWT to be used to authenticate
	$t2->get_ok('/me', { Authorization => "Bearer $jwt_token.$jwt_sig" })
		->status_is(401, 'user can\'t use his JWT to do anything else')
		->location_is('/user/me/password')
		->json_is({ error => 'unauthorized' });

	$t2->post_ok(
		'/login' => json => {
			user     => 'foo@conch.joyent.us',
			password => $insecure_password,
		})
		->status_is(401, 'user cannot log in with the same insecure password again')
		->json_is({ error => 'unauthorized' });

	$t2->post_ok(
		'/user/me/password' => { Authorization => "Bearer $jwt_token.$jwt_sig" }
			=> json => { password => 'a more secure password' })
		->status_is(204, 'user finally acquiesced and changed his password');

	my $secure_password = $_new_password;
	is($secure_password, 'a more secure password', 'provided password was saved to the db');

	$t2->post_ok(
		'/login' => json => {
			user     => 'foo@conch.joyent.us',
			password => $secure_password,
		})
		->status_is(200, 'user can log in with new password')
		->json_has('/jwt_token')
		->json_hasnt('/message');
	$jwt_token = $t2->tx->res->json->{jwt_token};
	$jwt_sig   = $t2->tx->res->cookie('jwt_sig')->value;

	$t2->get_ok('/me')
		->status_is(204, 'user can use his saved session again after changing his password');
	is($t2->tx->res->body, '', '...with no extra response messages');

	$t2->reset_session;	# force JWT to be used to authenticate
	$t2->get_ok('/me', { Authorization => "Bearer $jwt_token.$jwt_sig" })
		->status_is(204, 'user authenticate with JWT again after his password is changed');
	is($t2->tx->res->body, '', '...with no extra response messages');

	$t3->get_ok($t3->ua->server->url->userinfo('foo@conch.joyent.us:' . $secure_password)->path('/me'))
		->status_is(204, 'after user fixes his password, he can use basic auth again');


	$t->delete_ok("/user/foobar")
		->status_is(404, 'attempted to deactivate a non-existent user')
		->json_is({ error => "user foobar not found" });

	$t->delete_ok("/user/$new_user_id")
		->status_is(204, 'new user is deactivated');

	# we haven't cleared the user's session yet...
	$t2->get_ok('/me')
		->status_is(401, 'user cannot log in with saved browser session')
		->json_is({ 'error' => 'unauthorized' });

	$t2->reset_session;	# force JWT to be used to authenticate
	$t2->post_ok(
		'/login' => json => {
			user     => 'foo@conch.joyent.us',
			password => $secure_password,
		})
		->status_is(401, 'user can no longer log in with credentials')
		->json_is({ 'error' => 'unauthorized' });

	$t->delete_ok("/user/$new_user_id")
		->status_is(410, 'new user was already deactivated')
		->json_schema_is('UserError')
		->json_is('/error' => 'user was already deactivated')
		->json_is('/user/id' => $new_user_id, 'got user id')
		->json_is('/user/email' => 'foo@conch.joyent.us', 'got user email')
		->json_is('/user/name' => 'FOO', 'got user name');

	$new_user->discard_changes;
	ok($new_user->deactivated, 'user still exists, but is marked deactivated');

	$t->post_ok(
		'/user?send_mail=0',
		json => { email => 'foo@conch.joyent.us', name => 'FOO', password => '123' })
		->status_is(201, 'created user "again"');
	my $second_new_user_id = $t->tx->res->json->{id};

	isnt($second_new_user_id, $new_user_id, 'created user with a new id');
	my $second_new_user = $t->app->db_user_accounts->find($second_new_user_id);
	is($second_new_user->email, $new_user->email, '...but the email addresses are the same');
	is($second_new_user->name, $new_user->name, '...but the names are the same');

	warnings(sub {
		memory_cycle_ok($t2, 'no leaks in the Test::Conch object');
	});
};

warnings(sub {
	memory_cycle_ok($t, 'no leaks in the Test::Conch object');
});

done_testing();
