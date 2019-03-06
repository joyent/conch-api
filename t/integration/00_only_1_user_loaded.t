use strict;
use warnings FATAL => 'utf8';
use utf8;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More;
use Data::UUID;
use Path::Tiny;
use Test::Warnings ':all';
use Test::Conch;
use Test::Deep;
use Test::Deep::NumberTolerant;
use Time::HiRes 'time'; # time() now has µs precision
use Test::Memory::Cycle;

my $uuid = Data::UUID->new;

my $t = Test::Conch->new;
$t->load_fixture('conch_user_global_workspace');

$t->get_ok('/ping')
    ->status_is(200)
    ->json_is({ status => 'ok' })
    ->header_isnt('Request-Id' => undef)
    ->header_isnt('X-Request-ID' => undef);

$t->get_ok('/me')->status_is(401);
$t->get_ok('/login')->status_is(401);

my $now = Conch::Time->now;

$t->authenticate;

isa_ok($t->tx->res->cookie('conch'), 'Mojo::Cookie::Response');

my $conch_user = $t->app->db_user_accounts->search({ name => $t->CONCH_USER })->single;

ok($conch_user->last_login >= $now, 'user last_login is updated')
    or diag('last_login not updated: '.$conch_user->last_login.' is not updated to '.$now);


subtest 'User' => sub {
    $t->get_ok('/me')
        ->status_is(204)
        ->content_is('');

    $t->get_ok('/user/me/settings')
        ->status_is(200)
        ->json_is('', {});

    $t->get_ok('/user/me/settings/BAD')
        ->status_is(404);

    $t->post_ok('/user/me/settings/TEST' => json => { NOTTEST => 'test' })
        ->status_is(400)
        ->json_is({ error => "Setting key in request object must match name in the URL ('TEST')", });

    $t->post_ok('/user/me/settings/FOO/BAR', json => { 'FOO/BAR' => 1 })
        ->status_is(404);

    $t->post_ok('/user/me/settings/TEST' => json => { TEST => 'TEST' })
        ->status_is(200)
        ->content_is('');

    $t->get_ok('/user/me/settings/TEST')
        ->status_is(200)
        ->json_is('', { TEST => 'TEST' });

    $t->get_ok('/user/me/settings')
        ->status_is(200)
        ->json_is('', { TEST => 'TEST' });

    $t->post_ok('/user/me/settings/TEST2' => json => { TEST2 => { foo => 'bar' } })
        ->status_is(200)
        ->content_is('');

    $t->get_ok('/user/me/settings/TEST2')
        ->status_is(200)
        ->json_is('', { TEST2 => { foo => 'bar' } });

    $t->get_ok('/user/me/settings')
        ->status_is(200)
        ->json_is('', { TEST => 'TEST', TEST2 => { foo => 'bar' }, });

    $t->delete_ok('/user/me/settings/TEST')
        ->status_is(204)
        ->content_is('');

    $t->get_ok('/user/me/settings')
        ->status_is(200)
        ->json_is('', { TEST2 => { foo => 'bar' } });

    $t->delete_ok('/user/me/settings/TEST2')
        ->status_is(204)
        ->content_is('');

    $t->get_ok('/user/me/settings')
        ->status_is(200)
        ->json_is('', {});

    $t->get_ok('/user/me/settings/TEST')
        ->status_is(404);

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

    $t->authenticate;
    my @login_token = ($t->tx->res->json->{jwt_token}.'.'.$t->tx->res->cookie('jwt_sig')->value);
    {
        my $t2 = Test::Conch->new(pg => $t->pg);
        $t2->get_ok('/user/me', { Authorization => 'Bearer '.$login_token[0] })
            ->status_is(200, 'login token works without cookies etc')
            ->json_schema_is('UserDetailed')
            ->json_is('/email' => $t2->CONCH_EMAIL);
    }

    # get another JWT
    $t->authenticate;
    push @login_token, $t->tx->res->json->{jwt_token}.'.'.$t->tx->res->cookie('jwt_sig')->value;
    {
        my $t2 = Test::Conch->new(pg => $t->pg);
        $t2->get_ok('/user/me', { Authorization => 'Bearer '.$login_token[1] })
            ->status_is(200, 'second login token works without cookies etc')
            ->json_schema_is('UserDetailed')
            ->json_is('/email' => $t2->CONCH_EMAIL);
    }

    {
        my $t2 = Test::Conch->new(pg => $t->pg);
        $t2->get_ok('/user/me', { Authorization => 'Bearer '.$login_token[0] })
            ->status_is(200, 'and first login token still works')
            ->json_schema_is('UserDetailed')
            ->json_is('/email' => $t2->CONCH_EMAIL);
    }

    $t->post_ok('/user/me/token', json => { name => 'an api token' })
        ->status_is(201);
    my $api_token = $t->tx->res->json->{token};

    $t->post_ok('/user/me/password' => json => { password => 'øƕḩẳȋ' })
        ->status_is(204, 'changed password');

    $t->get_ok('/user/me/settings')
        ->status_is(401, 'session tokens revoked too');

    $t->post_ok('/login', json => { user => $t->CONCH_EMAIL, password => $t->CONCH_PASSWORD })
        ->status_is(401, 'cannot use old password after changing it');

    {
        my $t2 = Test::Conch->new(pg => $t->pg);
        $t2->get_ok('/user/me', { Authorization => 'Bearer '.$login_token[0] })
            ->status_is(401, 'main login token no longer works after changing password');
    }
    {
        my $t2 = Test::Conch->new(pg => $t->pg);
        $t2->get_ok('/user/me', { Authorization => 'Bearer '.$login_token[1] })
            ->status_is(401, 'second login token no longer works after changing password');
    }

    {
        my $t2 = Test::Conch->new(pg => $t->pg);
        $t2->get_ok('/user/me', { Authorization => 'Bearer '.$api_token })
            ->status_is(200, 'api token still works after changing password')
            ->json_schema_is('UserDetailed')
            ->json_is('/email' => $t2->CONCH_EMAIL);
    }

    $t->post_ok('/login', json => { user => $t->CONCH_EMAIL, password => 'øƕḩẳȋ' })
        ->status_is(200, 'logged in using new password');

    $t->post_ok('/user/me/password?clear_tokens=all' => json => { password => 'another password' })
        ->status_is(204, 'changed password again');

    {
        my $t2 = Test::Conch->new(pg => $t->pg);
        $t2->get_ok('/user/me', { Authorization => 'Bearer '.$api_token })
            ->status_is(401, 'api login token no longer works either');
    }

    $t->post_ok('/login', json => { user => $t->CONCH_EMAIL, password => 'another password' })
        ->status_is(200, 'logged in using second new password');

    $t->post_ok('/user/me/password', json => { password => $t->CONCH_PASSWORD })
        ->status_is(204, 'changed password back to original');

    $t->post_ok('/login', json => { user => $t->CONCH_EMAIL, password => $t->CONCH_PASSWORD })
        ->status_is(200, 'logged in using original password');

    $t->get_ok('/user/me/settings')
        ->status_is(200, 'original password works again');
};

my $global_ws_id = $t->app->db_workspaces->get_column('id')->single;
my %workspace_data;
my %users;

subtest 'Workspaces' => sub {
    $t->get_ok('/workspace/notauuid')
        ->status_is(404);

    $t->get_ok('/workspace')
        ->status_is(200)
        ->json_schema_is('WorkspacesAndRoles')
        ->json_is('', [{
            id          => $global_ws_id,
            name        => 'GLOBAL',
            role        => 'admin',
            description => 'Global workspace. Ancestor of all workspaces.',
            parent_id   => undef,
        }]);

    $workspace_data{conch}[0] = $t->tx->res->json->[0];

    $t->get_ok("/workspace/$global_ws_id")
        ->status_is(200)
        ->json_schema_is('WorkspaceAndRole')
        ->json_is('', $workspace_data{conch}[0], 'data for GLOBAL workspace, by id');

    $t->get_ok('/workspace/GLOBAL')
        ->status_is(200)
        ->json_schema_is('WorkspaceAndRole')
        ->json_is('', $workspace_data{conch}[0], 'data for GLOBAL workspace, by name');

    $t->get_ok('/workspace/'.$uuid->create_str())
        ->status_is(404);

    $t->get_ok("/workspace/$global_ws_id/user")
        ->status_is(200)
        ->json_schema_is('WorkspaceUsers')
        ->json_cmp_deeply('', [
            {
                id    => ignore,
                name  => $t->CONCH_USER,
                email => $t->CONCH_EMAIL,
                role  => 'admin',
            }
        ], 'data for users who can access GLOBAL');

    %users = (GLOBAL => $t->tx->res->json);

    is($t->app->db_user_workspace_roles->count, 1,
        'currently one user_workspace_role entry');

    $t->post_ok('/user?send_mail=0',
            json => { email => 'test_user@conch.joyent.us', name => 'test user', password => '123' })
        ->status_is(201, 'created new user test_user')
        ->json_schema_is('User');

    $t->post_ok("/workspace/$global_ws_id/user?send_mail=0" => json => {
            user => 'test_user@conch.joyent.us',
            role => 'rw',
        })
        ->status_is(201, 'added the user to the GLOBAL workspace');

    is($t->app->db_user_workspace_roles->count, 2,
        'now there is another user_workspace_role entry');

    is(
        $t->app->db_user_accounts
            ->search({ email => 'test_user@conch.joyent.us' })
            ->search_related('user_workspace_roles', { workspace_id => $global_ws_id })
            ->count,
        1,
        'new user can access this workspace',
    );

    $t->post_ok("/workspace/$global_ws_id/user?send_mail=0" => json => {
            user => 'test_user@conch.joyent.us',
            role => 'rw',
        })
        ->status_is(200, 'redundant add requests do nothing');

    is($t->app->db_user_workspace_roles->count, 2,
        'still just two user_workspace_role entries');

    $t->post_ok("/workspace/$global_ws_id/user?send_mail=0" => json => {
            user => 'test_user@conch.joyent.us',
            role => 'ro',
        })
        ->status_is(400)
        ->json_is({ error => "user test user already has rw access to workspace $global_ws_id: cannot downgrade role to ro" });

    $t->get_ok('/user/email=test_user@conch.joyent.us')
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is('/email' => 'test_user@conch.joyent.us')
        ->json_is('/workspaces' => [{
                id => $global_ws_id,
                name => 'GLOBAL',
                description => 'Global workspace. Ancestor of all workspaces.',
                role => 'rw',
                parent_id => undef,
            }]);

    $workspace_data{test_user} = $t->tx->res->json->{workspaces};

    $t->get_ok('/user/')
        ->status_is(200)
        ->json_schema_is('UsersDetailed')
        ->json_is('/0/email', $t->CONCH_EMAIL)
        ->json_is('/0/workspaces' => [ $workspace_data{conch}[0] ])
        ->json_is('/1/email', 'test_user@conch.joyent.us')
        ->json_is('/1/workspaces' => [ $workspace_data{test_user}[0] ]);

    my $main_user_id = $t->tx->res->json->[0]{id};
    my $test_user_id = $t->tx->res->json->[1]{id};

    push $users{GLOBAL}->@*, {
        id    => ignore,
        name  => 'test user',
        email => 'test_user@conch.joyent.us',
        role  => 'rw',
    };

    $t->get_ok("/workspace/$global_ws_id/user")
        ->status_is(200)
        ->json_schema_is('WorkspaceUsers')
        ->json_cmp_deeply('', bag($users{GLOBAL}->@*), 'updated data for users who can access GLOBAL');
};

subtest 'Sub-Workspace' => sub {
    $t->get_ok("/workspace/$global_ws_id/child")
        ->status_is(200)
        ->json_schema_is('WorkspacesAndRoles')
        ->json_is('', []);

    $t->post_ok("/workspace/$global_ws_id/child")
        ->status_is(400, 'No body is bad request')
        ->json_like('/error', qr/Expected object/);

    $t->post_ok("/workspace/$global_ws_id/child", json => { name => 'foo/bar' })
        ->status_is(400)
        ->json_cmp_deeply({ error => re(qr/name: .*does not match/) });

    $t->post_ok("/workspace/$global_ws_id/child", json => { name => 'foo.bar' })
        ->status_is(400)
        ->json_cmp_deeply({ error => re(qr/name: .*does not match/) });

    $t->post_ok("/workspace/$global_ws_id/child" => json => { name => 'GLOBAL' })
        ->status_is(400, 'Cannot create duplicate workspace')
        ->json_is('', { error => "workspace 'GLOBAL' already exists" });

    $t->post_ok("/workspace/$global_ws_id/child" => json => {
            name        => 'child_ws',
            description => 'one level of workspaces',
        })
        ->status_is(201)
        ->json_schema_is('WorkspaceAndRole')
        ->json_cmp_deeply({
            id          => ignore,
            name        => 'child_ws',
            description => 'one level of workspaces',
            parent_id   => $global_ws_id,
            role        => 'admin',
            role_via    => $global_ws_id,
        });

    my $child_ws_id = $t->tx->res->json->{id};
    $workspace_data{conch}[1] = $t->tx->res->json;

    $t->get_ok("/workspace/$global_ws_id/child")
        ->status_is(200)
        ->json_schema_is('WorkspacesAndRoles')
        ->json_is('', [ $workspace_data{conch}[1] ], 'data for workspaces under GLOBAL, by id');

    $t->get_ok('/workspace/GLOBAL/child')
        ->status_is(200)
        ->json_schema_is('WorkspacesAndRoles')
        ->json_is('', [ $workspace_data{conch}[1] ], 'data for workspaces under GLOBAL, by name');

    $t->get_ok("/workspace/$child_ws_id")
        ->status_is(200)
        ->json_schema_is('WorkspaceAndRole')
        ->json_is('', $workspace_data{conch}[1], 'data for subworkspace, by id');

    $t->get_ok('/workspace/child_ws')
        ->status_is(200)
        ->json_schema_is('WorkspaceAndRole')
        ->json_is('', $workspace_data{conch}[1], 'data for subworkspace, by name');

    $t->post_ok("/workspace/$child_ws_id/child" =>
            json => { name => 'grandchild_ws', description => 'two levels of subworkspaces', })
        ->status_is(201, 'created a grandchild workspace')
        ->json_schema_is('WorkspaceAndRole')
        ->json_cmp_deeply({
            id          => ignore,
            name        => 'grandchild_ws',
            description => 'two levels of subworkspaces',
            parent_id   => $child_ws_id,
            role        => 'admin',
            role_via    => $global_ws_id,
        });

    my $grandchild_ws_id = $t->tx->res->json->{id};
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

    $t->get_ok('/user/email='.$t->CONCH_EMAIL)
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is('/email' => $t->CONCH_EMAIL)
        ->json_is('/workspaces' => [
                $workspace_data{conch}[0],
                $workspace_data{conch}[1],
                $workspace_data{conch}[2],
            ],
            'main user has access to all workspaces via GLOBAL');

    $t->get_ok('/user/me')
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is('/email' => $t->CONCH_EMAIL)
        ->json_is('/workspaces' => [
                $workspace_data{conch}[0],
                $workspace_data{conch}[1],
                $workspace_data{conch}[2],
            ],
            '/user/me returns the same data');

    $t->get_ok('/user/email=test_user@conch.joyent.us')
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is('/email' => 'test_user@conch.joyent.us')
        ->json_is('/workspaces' => [
                {
                    id => $global_ws_id,
                    name => 'GLOBAL',
                    description => 'Global workspace. Ancestor of all workspaces.',
                    parent_id => undef,
                    role => 'rw',
                },
                {
                    id => $child_ws_id,
                    name => 'child_ws',
                    description => 'one level of workspaces',
                    parent_id => $global_ws_id,
                    role => 'rw',
                    role_via => $global_ws_id,
                },
                {
                    id => $grandchild_ws_id,
                    name => 'grandchild_ws',
                    description => 'two levels of subworkspaces',
                    parent_id => $child_ws_id,
                    role => 'rw',
                    role_via => $global_ws_id,
                },
            ],
            'new user has access to all workspaces via GLOBAL');

    $workspace_data{test_user} = $t->tx->res->json->{workspaces};

    $t->get_ok('/user')
        ->status_is(200, 'data for all users, all workspaces')
        ->json_schema_is('UsersDetailed')
        ->json_is('/0/email', $t->CONCH_EMAIL)
        ->json_is('/0/workspaces' => $workspace_data{conch})
        ->json_is('/1/email', 'test_user@conch.joyent.us')
        ->json_is('/1/workspaces' => $workspace_data{test_user});

    my $main_user_id = $t->tx->res->json->[0]{id};
    my $test_user_id = $t->tx->res->json->[1]{id};

    $users{child_ws} = [ map {; +{ $_->%*, role_via => $global_ws_id } } $users{GLOBAL}->@* ];
    $users{grandchild_ws} = [ map {; +{ $_->%*, role_via => $global_ws_id } } $users{GLOBAL}->@* ];

    $t->get_ok("/workspace/$child_ws_id/user")
        ->status_is(200)
        ->json_schema_is('WorkspaceUsers')
        ->json_cmp_deeply('', bag($users{child_ws}->@*), 'data for users who can access subworkspace');

    $t->get_ok("/workspace/$grandchild_ws_id/user")
        ->status_is(200)
        ->json_schema_is('WorkspaceUsers')
        ->json_cmp_deeply('', bag($users{grandchild_ws}->@*), 'data for users who can access grandchild workspace');

    $t->post_ok("/workspace/$grandchild_ws_id/user?send_mail=0" => json => {
            user => 'test_user@conch.joyent.us',
            role => 'rw',
        })
        ->status_is(200, 'redundant add requests do nothing');

    is($t->app->db_user_workspace_roles->count, 2,
        'still just two user_workspace_role entries');

    $t->post_ok("/workspace/$grandchild_ws_id/user?send_mail=0" => json => {
            user => 'test_user@conch.joyent.us',
            role => 'ro',
        })
        ->status_is(400)
        ->json_is({ error => "user test user already has rw access to workspace $grandchild_ws_id via workspace $global_ws_id: cannot downgrade role to ro" });

    $t->post_ok("/workspace/$grandchild_ws_id/user?send_mail=0" => json => {
            user => 'test_user@conch.joyent.us',
            role => 'admin',
        })
        ->status_is(201, 'can upgrade existing permission');

    is($t->app->db_user_workspace_roles->count, 3,
        'now there are three user_workspace_role entries');

    # now let's try manipulating permissions on the workspace in the middle of the hierarchy

    $t->post_ok("/workspace/$child_ws_id/user?send_mail=0" => json => {
            user => 'test_user@conch.joyent.us',
            role => 'rw',
        })
        ->status_is(200, 'redundant add requests do nothing');

    $t->post_ok("/workspace/$child_ws_id/user?send_mail=0" => json => {
            user => 'test_user@conch.joyent.us',
            role => 'ro',
        })
        ->status_is(400)
        ->json_is({ error => "user test user already has rw access to workspace $child_ws_id via workspace $global_ws_id: cannot downgrade role to ro" });

    is($t->app->db_user_workspace_roles->count, 3,
        'still just three user_workspace_role entries');

    $t->post_ok("/workspace/$child_ws_id/user?send_mail=0" => json => {
            user => 'test_user@conch.joyent.us',
            role => 'admin',
        })
        ->status_is(201, 'can upgrade existing permission');

    is($t->app->db_user_workspace_roles->count, 4,
        'now there are four user_workspace_role entries');

    # update our idea of what all the permissions should look like:
    $workspace_data{test_user}[1]{role} = 'admin';
    delete $workspace_data{test_user}[1]{role_via};
    $workspace_data{test_user}[2]{role} = 'admin';
    delete $workspace_data{test_user}[2]{role_via};

    $t->get_ok('/user/email='.$t->CONCH_EMAIL)
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is('/email' => $t->CONCH_EMAIL)
        ->json_is('/workspaces' => [
                $workspace_data{conch}[0],
                $workspace_data{conch}[1],
                $workspace_data{conch}[2],
            ],
            'main user has access to all workspaces via GLOBAL');

    $t->get_ok('/user/email=test_user@conch.joyent.us')
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is('/email' => 'test_user@conch.joyent.us')
        ->json_cmp_deeply('/workspaces' => bag(
                $workspace_data{test_user}[0],
                $workspace_data{test_user}[1],
                $workspace_data{test_user}[2],
            ),
            'test user now has direct access to all workspaces');

    $t->get_ok('/user')
        ->status_is(200, 'data for all users, all workspaces')
        ->json_schema_is('UsersDetailed')
        ->json_is('/0/email', $t->CONCH_EMAIL)
        ->json_cmp_deeply('/0/workspaces' => bag($workspace_data{conch}->@*))
        ->json_is('/1/email', 'test_user@conch.joyent.us')
        ->json_cmp_deeply('/1/workspaces' => bag($workspace_data{test_user}->@*));

    $t->delete_ok("/workspace/$child_ws_id/user/email=test_user\@conch.joyent.us")
        ->status_is(201, 'extra permissions for user are removed from the sub workspace and its children');

    $workspace_data{test_user}[1]->@{qw(role role_via)} = ('rw', $global_ws_id);
    $workspace_data{test_user}[2]->@{qw(role role_via)} = ('rw', $global_ws_id);

    $t->get_ok('/user/email=test_user@conch.joyent.us')
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is('/email' => 'test_user@conch.joyent.us')
        ->json_cmp_deeply('/workspaces' => $workspace_data{test_user},
            'test user now only has rw access to everything again (via GLOBAL)');

    $t->delete_ok("/workspace/$child_ws_id/user/email=test_user\@conch.joyent.us")
        ->status_is(201, 'deleting again is a no-op');

    $t->post_ok('/user',
            json => { email => 'untrusted/user@conch.joyent.us', name => 'me', password => '123' })
        ->status_is(400)
        ->json_cmp_deeply({ error => re(qr/email: .*does not match/) });

    $t->post_ok('/user',
            json => { email => 'untrusted_user@conch.joyent.us', name => 'me', password => '123' })
        ->status_is(400)
        ->json_is({ error => 'user name "me" is prohibited' });

    $t->post_ok('/user?send_mail=0',
            json => { email => 'untrusted_user@conch.joyent.us', name => 'untrusted user', password => '123' })
        ->status_is(201, 'created new untrusted user')
        ->json_schema_is('User');

    $t->post_ok('/workspace/child_ws/user?send_mail=0' => json => {
            user => 'untrusted_user@conch.joyent.us',
            role => 'ro',
        })
        ->status_is(201, 'added the user to the child workspace');

    $t->get_ok('/workspace/GLOBAL/user')
        ->status_is(200)
        ->json_schema_is('WorkspaceUsers')
        ->json_cmp_deeply('', bag($users{GLOBAL}->@*), 'no change to users who can access GLOBAL');

    push $users{child_ws}->@*, {
        id    => ignore,
        name  => 'untrusted user',
        email => 'untrusted_user@conch.joyent.us',
        role  => 'ro',
    };
    push $users{grandchild_ws}->@*, {
        $users{child_ws}[2]->%*,
        role_via => $child_ws_id,
    };

    $t->get_ok('/workspace/child_ws/user')
        ->status_is(200)
        ->json_schema_is('WorkspaceUsers')
        ->json_cmp_deeply('', bag($users{child_ws}->@*), 'updated data for users who can access child ws');

    $t->get_ok('/workspace/grandchild_ws/user')
        ->status_is(200)
        ->json_schema_is('WorkspaceUsers')
        ->json_cmp_deeply('', bag($users{grandchild_ws}->@*), 'updated data for users who can access grandchild ws');

    $workspace_data{untrusted_user} = [
        {
            $workspace_data{conch}[1]->%{qw(id name description parent_id)},
            role => 'ro',
        },
        {
            $workspace_data{conch}[2]->%{qw(id name description parent_id)},
            role => 'ro',
            role_via => $child_ws_id,
        },
    ];

    $t->get_ok('/user/')
        ->status_is(200)
        ->json_schema_is('UsersDetailed')
        ->json_is('/0/email', $t->CONCH_EMAIL)
        ->json_is('/0/workspaces' => $workspace_data{conch})
        ->json_is('/1/email', 'test_user@conch.joyent.us')
        ->json_is('/1/workspaces' => $workspace_data{test_user})
        ->json_is('/2/email', 'untrusted_user@conch.joyent.us')
        ->json_is('/2/workspaces' => $workspace_data{untrusted_user});


    my $untrusted = Test::Conch->new(pg => $t->pg);
    $untrusted->authenticate(user => 'untrusted_user@conch.joyent.us', password => '123');

    # this user cannot be shown the GLOBAL workspace or its id
    undef $workspace_data{untrusted_user}[0]{parent_id};
    delete $users{GLOBAL};

    $untrusted->get_ok('/workspace/GLOBAL')
        ->status_is(403, 'new user not authorized to view GLOBAL');

    $untrusted->get_ok('/workspace/child_ws')
        ->status_is(200)
        ->json_schema_is('WorkspaceAndRole')
        ->json_is('', $workspace_data{untrusted_user}[0], 'data for child workspace');

    $untrusted->get_ok('/workspace/grandchild_ws')
        ->status_is(200)
        ->json_schema_is('WorkspaceAndRole')
        ->json_is('', $workspace_data{untrusted_user}[1], 'data for grandchild workspace');

    $untrusted->get_ok('/user')
        ->status_is(403, 'system admin privs required for this endpoint');

    $untrusted->get_ok('/workspace/GLOBAL/user')
        ->status_is(403, 'new user not authorized to view GLOBAL');

    $untrusted->get_ok('/workspace/child_ws/user')
        ->status_is(200)
        ->json_schema_is('WorkspaceUsers')
        ->json_cmp_deeply('', bag($users{child_ws}->@*), 'user gets the same list of users who can access child ws');

    $untrusted->get_ok('/workspace/grandchild_ws/user')
        ->status_is(200)
        ->json_schema_is('WorkspaceUsers')
        ->json_cmp_deeply('', bag($users{grandchild_ws}->@*), 'user gets the same list of users who can access grandchild ws');
};

subtest 'Relays' => sub {
    $t->post_ok('/relay/deadbeef/register',
            json => {
                serial   => 'deadbeef',
                version  => '0.0.1',
                ipaddr   => '127.0.0.1',
                ssh_port => 22,
                alias    => 'test relay',
            })
        ->status_is(204);

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
                ssh_port => 22,
                alias    => 'test relay',
                created  => $relay->created,
                updated  => $relay->updated,
            }
        ]);

    $relay->user_relay_connections->update({
        first_seen => '1999-01-01',
        last_seen => '1999-01-01',
    });

    $t->post_ok('/relay/deadbeef/register',
            json => {
                serial   => 'deadbeef',
                version  => '0.0.2',
                ipaddr   => '127.0.0.1',
                ssh_port => 22,
                alias    => 'test relay',
            })
        ->status_is(204);

    $relay->discard_changes;  # reload from db

    $t->get_ok('/relay')
        ->status_is(200)
        ->json_schema_is('Relays')
        ->json_is('', [
            {
                id => 'deadbeef',
                version  => '0.0.2',
                ipaddr   => '127.0.0.1',
                ssh_port => 22,
                alias    => 'test relay',
                created  => $relay->created,
                updated  => $relay->updated,
            }
        ], 'version was updated');
    my $y2000 = Conch::Time->new(year => 2000);
    cmp_ok(($relay->user_relay_connections)[0]->first_seen, '<', $y2000, 'first_seen was not updated');
    cmp_ok(($relay->user_relay_connections)[0]->last_seen, '>', $y2000, 'last_seen was updated');
};

subtest 'Log out' => sub {
    $t->post_ok("/logout")
        ->status_is(204);
    $t->get_ok("/workspace")
        ->status_is(401);
};

subtest 'JWT authentication' => sub {
    $t->authenticate(bailout => 0)->json_has('/jwt_token');

    my $jwt_token = $t->tx->res->json->{jwt_token};
    my $jwt_sig   = $t->tx->res->cookie('jwt_sig')->value;

    $t->get_ok("/workspace", { Authorization => "Bearer $jwt_token" })
        ->status_is(200, "user can provide JWT token with cookie to authenticate");
    $t->reset_session;  # force JWT to be used to authenticate
    $t->get_ok("/workspace", { Authorization => "Bearer $jwt_token.$jwt_sig" })
        ->status_is(200, "user can provide Authentication header with full JWT to authenticate");

    $t->post_ok('/refresh_token', { Authorization => "Bearer $jwt_token.$jwt_sig" })
        ->status_is(200)
        ->json_has('/jwt_token');

    my $new_jwt_token = $t->tx->res->json->{jwt_token};
    $t->get_ok("/workspace", { Authorization => "Bearer $new_jwt_token" })
        ->status_is(200, "Can authenticate with new token");
    $t->get_ok("/workspace", { Authorization => "Bearer $jwt_token.$jwt_sig" })
        ->status_is(401, "Cannot use old token");

    $t->get_ok('/me', { Authorization => "Bearer $jwt_token.$jwt_sig" })
        ->status_is(401, 'Cannot reuse old JWT');

    $t->post_ok('/user/email='.$t->CONCH_EMAIL.'/revoke?api_only=1',
            { Authorization => 'Bearer '.$new_jwt_token })
        ->status_is(204, 'Revoke api tokens for user');
    $t->get_ok('/workspace', { Authorization => 'Bearer '.$new_jwt_token })
        ->status_is(200, 'user can still use the login token');
    $t->post_ok('/user/email='.$t->CONCH_EMAIL.'/revoke',
            { Authorization => "Bearer $new_jwt_token" })
        ->status_is(204, 'Revoke all tokens for user');
    $t->get_ok("/workspace", { Authorization => "Bearer $new_jwt_token" })
        ->status_is(401, "Cannot use after user revocation");
    $t->post_ok('/refresh_token', { Authorization => "Bearer $new_jwt_token" })
        ->status_is(401, "Cannot use after user revocation");

    $t->authenticate(bailout => 0);
    my $jwt_token_2 = $t->tx->res->json->{jwt_token};
    $t->post_ok('/user/me/revoke', { Authorization => "Bearer $jwt_token_2" })
        ->status_is(204, "Revoke tokens for self");
    $t->get_ok("/workspace", { Authorization => "Bearer $jwt_token_2" })
        ->status_is(401, "Cannot use after self revocation");

    $t->authenticate;
};

subtest 'modify another user' => sub {
    $t->post_ok('/user?send_mail=0', json => { name => 'me', email => 'foo@conch.joyent.us' })
        ->status_is(400, 'user name "me" is prohibited')
        ->json_is({ error => 'user name "me" is prohibited' });

    $t->post_ok('/user?send_mail=0', json => { name => 'foo', email => $t->CONCH_EMAIL })
        ->status_is(409, 'cannot create user with a duplicate email address')
        ->json_schema_is('UserError')
        ->json_is({
                error => 'duplicate user found',
                user => {
                    id => $conch_user->id,
                    email => $t->CONCH_EMAIL,
                    name => $t->CONCH_USER,
                    created => $conch_user->created,
                    deactivated => undef,
                }
            });

    $t->post_ok('/user?send_mail=0',
            json => { name => $t->CONCH_USER, email => uc($t->CONCH_EMAIL) })
        ->status_is(409, 'emails are not case sensitive when checking for duplicate users')
        ->json_schema_is('UserError')
        ->json_is({
                error => 'duplicate user found',
                user => {
                    id => $conch_user->id,
                    email => $t->CONCH_EMAIL,
                    name => $t->CONCH_USER,
                    created => $conch_user->created,
                    deactivated => undef,
                }
            });

    $t->post_ok('/user?send_mail=0',
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

    $t->post_ok('/user?send_mail=0',
            json => { email => 'foo@conch.joyent.us', name => 'foo', password => '123' })
        ->status_is(409, 'cannot create the same user again')
        ->json_schema_is('UserError')
        ->json_is('/error' => 'duplicate user found')
        ->json_is('/user/id' => $new_user_id, 'got user id')
        ->json_is('/user/email' => 'foo@conch.joyent.us', 'got user email')
        ->json_is('/user/name' => 'foo', 'got user name')
        ->json_is('/user/deactivated' => undef, 'got user deactivated date');

    $t->post_ok('/user/email=foo@conch.joyent.us', json => { email => 'test_user@conch.joyent.us' })
        ->status_is(409)
        ->json_cmp_deeply({
            error => 'duplicate user found',
            user => superhashof({
                email => 'test_user@conch.joyent.us',
                name => 'test user',
                deactivated => undef,
            }),
        });

    $t->post_ok('/user/email=foo@conch.joyent.us',
            json => { name => 'FOO', is_admin => JSON::PP::true })
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is('', {
            %$new_user_data,
            name => 'FOO',
            is_admin => JSON::PP::true,
        });

    my $t2 = Test::Conch->new(pg => $t->pg);
    $t2->post_ok('/login' => json => { user => 'foo@conch.joyent.us', password => '123' })
        ->status_is(200, 'new user can log in');
    my $jwt_token = $t2->tx->res->json->{jwt_token};
    my $jwt_sig   = $t2->tx->res->cookie('jwt_sig')->value;

    $t2->get_ok('/me')->status_is(204);

    $t2->post_ok('/user/me/token', json => { name => 'my api token' })
        ->status_is(201);
    my $api_token = $t2->tx->res->json->{token};

    my $t3 = Test::Conch->new(pg => $t->pg); # we will only use this $mojo for basic auth
    $t3->get_ok($t3->ua->server->url->userinfo('foo@conch.joyent.us:123')->path('/me'))
        ->status_is(204, 'user can also use the app with basic auth');

    $t->post_ok("/user/$new_user_id/revoke?login_only=1")
        ->status_is(204, 'revoked login tokens for the new user');

    $t2->get_ok('/me')
        ->status_is(401, 'persistent session cleared when login tokens are revoked');

    $t2->get_ok('/me', { Authorization => "Bearer $jwt_token.$jwt_sig" })
        ->status_is(401, 'new user cannot authenticate with the login JWT after login tokens are revoked');

    $t2->get_ok('/me', { Authorization => 'Bearer '.$api_token })
        ->status_is(204, 'new user can still use the api token');

    $t->post_ok("/user/$new_user_id/revoke?api_only=1")
        ->status_is(204, 'revoked api tokens for the new user');

    $t2->get_ok('/me', { Authorization => "Bearer $api_token" })
        ->status_is(401, 'new user cannot authenticate with the api token after api tokens are revoked');

    $t2->post_ok('/login' => json => { user => 'foo@conch.joyent.us', password => '123' })
        ->status_is(200, 'new user can still log in again');
    $jwt_token = $t2->tx->res->json->{jwt_token};
    $jwt_sig   = $t2->tx->res->cookie('jwt_sig')->value;

    $t2->get_ok('/me')->status_is(204, 'session token re-established');

    $t2->post_ok('/user/me/token', json => { name => 'my api token' })
        ->status_is(201, 'got a new api token');
    $api_token = $t2->tx->res->json->{token};

    $t2->reset_session; # force JWT to be used to authenticate
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

    $t->delete_ok('/user/foobar/password?send_password_reset_mail=0')
        ->status_is(400, 'bad format')
        ->json_is({ error => 'invalid identifier format for foobar' });

    $t->delete_ok('/user/email=foobar/password?send_password_reset_mail=0')
        ->status_is(400, 'bad format')
        ->json_is({ error => 'invalid identifier format for email=foobar' });

    $t->delete_ok('/user/email=foobar@conch.joyent.us/password?send_password_reset_mail=0')
        ->status_is(404, 'attempted to reset the password for a non-existent user');

    $t->delete_ok("/user/$new_user_id/password?send_password_reset_mail=0")
        ->status_is(204, 'reset the new user\'s password');

    $t->delete_ok('/user/email=FOO@CONCH.JOYENT.US/password?send_password_reset_mail=0')
        ->status_is(204, 'reset the new user\'s password again, using (case insensitive) email lookup');
    my $insecure_password = $_new_password;

    $t2->get_ok('/me')
        ->status_is(401, 'user can no longer use his saved session after his password is changed');

    $t2->reset_session; # force JWT to be used to authenticate
    $t2->get_ok('/me', { Authorization => "Bearer $jwt_token.$jwt_sig" })
        ->status_is(401, 'user cannot authenticate with login JWT after his password is changed');

    $t2->get_ok('/user/me', { Authorization => 'Bearer '.$api_token })
        ->status_is(200, 'but the api token still works after his password is changed')
        ->json_schema_is('UserDetailed')
        ->json_is('/email' => 'foo@conch.joyent.us');

    $t2->post_ok('/login' => json => { user => 'foo@conch.joyent.us', password => 'foo', })
        ->status_is(401, 'cannot log in with the old password');

    $t3->get_ok($t3->ua->server->url->userinfo('foo@conch.joyent.us:'.$insecure_password)->path('/me'))
        ->status_is(401, 'user cannot use new password with basic auth to go anywhere else')
        ->location_is('/user/me/password');

    $t2->post_ok('/login' => json => { user => 'foo@conch.joyent.us', password => $insecure_password, })
        ->status_is(200, 'user can log in with new password')
        ->location_is('/user/me/password');
    $jwt_token = $t2->tx->res->json->{jwt_token};
    $jwt_sig   = $t2->tx->res->cookie('jwt_sig')->value;
    cmp_ok($t2->tx->res->cookie('jwt_sig')->expires, '<', time + 11 * 60, 'JWT expires in 10 minutes');

    $t2->get_ok('/me')
        ->status_is(401, 'user can\'t use his session to do anything else')
        ->location_is('/user/me/password');

    $t2->reset_session; # force JWT to be used to authenticate
    $t2->get_ok('/me', { Authorization => "Bearer $jwt_token.$jwt_sig" })
        ->status_is(401, 'user can\'t use his JWT to do anything else')
        ->location_is('/user/me/password');

    $t2->post_ok('/login' => json => { user => 'foo@conch.joyent.us', password => $insecure_password, })
        ->status_is(401, 'user cannot log in with the same insecure password again');

    $t2->post_ok('/user/me/password' => { Authorization => "Bearer $jwt_token.$jwt_sig" }
            => json => { password => 'a more secure password' })
        ->status_is(204, 'user finally acquiesced and changed his password');

    my $secure_password = $_new_password;
    is($secure_password, 'a more secure password', 'provided password was saved to the db');

    $t2->post_ok('/login' => json => { user => 'foo@conch.joyent.us', password => $secure_password, })
        ->status_is(200, 'user can log in with new password')
        ->json_has('/jwt_token')
        ->json_hasnt('/message');
    $jwt_token = $t2->tx->res->json->{jwt_token};
    $jwt_sig   = $t2->tx->res->cookie('jwt_sig')->value;

    $t2->get_ok('/me')
        ->status_is(204, 'user can use his saved session again after changing his password');
    is($t2->tx->res->body, '', '...with no extra response messages');

    $t2->reset_session; # force JWT to be used to authenticate
    $t2->get_ok('/me', { Authorization => "Bearer $jwt_token.$jwt_sig" })
        ->status_is(204, 'user authenticate with JWT again after his password is changed');
    is($t2->tx->res->body, '', '...with no extra response messages');

    $t3->get_ok($t3->ua->server->url->userinfo('foo@conch.joyent.us:'.$secure_password)->path('/me'))
        ->status_is(204, 'after user fixes his password, he can use basic auth again');


    $t->delete_ok('/user/email=foobar@joyent.conch.us')
        ->status_is(404, 'attempted to deactivate a non-existent user');

    $t->delete_ok("/user/$new_user_id")
        ->status_is(204, 'new user is deactivated');

    # we haven't cleared the user's session yet...
    $t2->get_ok('/me')
        ->status_is(401, 'user cannot log in with saved browser session');

    $t2->reset_session; # force JWT to be used to authenticate
    $t2->post_ok('/login' => json => { user => 'foo@conch.joyent.us', password => $secure_password, })
        ->status_is(401, 'user can no longer log in with credentials');

    $t->delete_ok("/user/$new_user_id")
        ->status_is(410, 'new user was already deactivated')
        ->json_schema_is('UserError')
        ->json_is('/error' => 'user was already deactivated')
        ->json_is('/user/id' => $new_user_id, 'got user id')
        ->json_is('/user/email' => 'foo@conch.joyent.us', 'got user email')
        ->json_is('/user/name' => 'FOO', 'got user name');

    $new_user->discard_changes;
    ok($new_user->deactivated, 'user still exists, but is marked deactivated');

    $t->post_ok('/user?send_mail=0',
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

subtest 'user tokens (our own)' => sub {
    $t->authenticate;   # make sure we have an unexpired JWT

    $t->get_ok('/user/me/token')
        ->status_is(200)
        ->json_schema_is('UserTokens')
        ->json_cmp_deeply([]);

    my @login_tokens = $conch_user->user_session_tokens->login_only->unexpired->all;

    $t->post_ok('/user/me/token', json => { name => 'login_jwt_1234' })
        ->status_is(400)
        ->json_is({ error => 'name "login_jwt_1234" is reserved' });

    $t->post_ok('/user/me/token', json => { name => 'my first 💩 // to.ken @@' })
        ->status_is(201)
        ->json_schema_is('NewUserToken')
        ->location_is('/user/me/token/my first 💩 // to.ken @@')
        ->json_cmp_deeply({
            name => 'my first 💩 // to.ken @@',
            token => re(qr/^[^.]+\.[^.]+\.[^.]+$/), # full jwt with signature
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            last_used => undef,
            expires => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        });
    my ($created, $expires, $jwt) = $t->tx->res->json->@{qw(created expires token)};

    cmp_deeply(
        Conch::Time->new($expires)->epoch,
        within_tolerance(time + 60*60*24*365*5, plus_or_minus => 10),
        'token expires approximately 5 years in the future',
    );

    $t->get_ok('/user/me/token')
        ->status_is(200)
        ->json_schema_is('UserTokens')
        ->json_is([
            {
                name => 'my first 💩 // to.ken @@',
                created => $created,
                last_used => undef,
                expires => $expires,
            },
        ]);

    $t->get_ok('/user/me/token/'.$login_tokens[0]->name)
        ->status_is(404, 'cannot retrieve login tokens');

    $t->get_ok('/user/me/token/my first 💩 // to.ken @@')
        ->status_is(200)
        ->json_schema_is('UserToken')
        ->json_is({
            name => 'my first 💩 // to.ken @@',
            created => $created,
            last_used => undef,
            expires => $expires,
        });

    $t->post_ok('/user/me/token', json => { name => 'my first 💩 // to.ken @@' })
        ->status_is(400)
        ->json_is({ error => 'name "my first 💩 // to.ken @@" is already in use' });

    my $t2 = Test::Conch->new(pg => $t->pg);
    $t2->get_ok('/user/me', { Authorization => 'Bearer '.$jwt })
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is('/email' => $t2->CONCH_EMAIL);
    undef $t2;

    $t->delete_ok('/user/me/token/my first 💩 // to.ken @@')
        ->status_is(204)
        ->content_is('');

    $t->get_ok('/user/me/token/my first 💩 // to.ken @@')
        ->status_is(404);

    my $last_used = $t->app->db_user_session_tokens->search({ name => 'my first 💩 // to.ken @@' })
        ->as_epoch('last_used')->get_column('last_used')->single;

    cmp_deeply(
        $last_used,
        within_tolerance(time, plus_or_minus => 10),
        'token was last used approximately now',
    );

    $t->get_ok('/user/me/token')
        ->status_is(200)
        ->json_schema_is('UserTokens')
        ->json_is([]);

    $t->get_ok('/user/me/token/my first 💩 // to.ken @@')
        ->status_is(404);

    $t->delete_ok('/user/me/token/my first 💩 // to.ken @@')
        ->status_is(404);

    $t2 = Test::Conch->new(pg => $t->pg);
    $t2->get_ok('/user/me', { Authorization => 'Bearer '.$jwt })
        ->status_is(401);

    # session was wiped; need to re-auth.
    $t->authenticate;
};

subtest 'user tokens (someone else\'s)' => sub {
    my ($email, $password) = ('foo@conch.joyent.us', 'neupassword');

    $t->get_ok('/user/email='.$email.'/token')
        ->status_is(200)
        ->json_schema_is('UserTokens')
        ->json_is([]);

    # password was set to something random when the user was (re)created
    $t->app->db_user_accounts->active->find({ email => $email })->update({ password => $password });

    my $t_other_user = Test::Conch->new(pg => $t->pg);
    $t_other_user->authenticate(user => $email, password => $password);

    $t_other_user->post_ok('/user/me/token', json => { name => 'my first 💩 // to.ken @@' })
        ->status_is(201)
        ->json_schema_is('NewUserToken')
        ->location_is('/user/me/token/my first 💩 // to.ken @@');
    my @jwts = $t_other_user->tx->res->json->{token};

    $t->get_ok('/user/email='.$email.'/token')
        ->status_is(200)
        ->json_schema_is('UserTokens')
        ->json_cmp_deeply([
            {
                name => 'my first 💩 // to.ken @@',
                created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
                last_used => ignore,
                expires => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            },
        ]);
    my @tokens = $t->tx->res->json->@*;

    $t->get_ok('/user/email='.$email.'/token/'.$tokens[0]->{name})
        ->status_is(200)
        ->json_schema_is('UserToken')
        ->json_is($tokens[0]);

    # can't use the sysadmin endpoints, even to ask about ourself
    $t_other_user->get_ok('/user/email='.$email.'/token')
        ->status_is(403);
    $t_other_user->get_ok('/user/email='.$email.'/token/foo')
        ->status_is(403);
    $t_other_user->delete_ok('/user/email='.$email.'/token/foo')
        ->status_is(403);

    $t_other_user->post_ok('/user/me/token', json => { name => 'my second token' })
        ->status_is(201)
        ->json_schema_is('NewUserToken')
        ->location_is('/user/me/token/my second token');
    push @jwts, $t_other_user->tx->res->json->{token};

    $t->get_ok('/user/email='.$email.'/token')
        ->status_is(200)
        ->json_schema_is('UserTokens')
        ->json_cmp_deeply([
            @tokens,
            {
                name => 'my second token',
                created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
                last_used => ignore,
                expires => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            },
        ]);
    @tokens = $t->tx->res->json->@*;

    $t->delete_ok('/user/email='.$email.'/token/'.$tokens[0]->{name})
        ->status_is(204);

    $t->get_ok('/user/email='.$email.'/token')
        ->status_is(200)
        ->json_schema_is('UserTokens')
        ->json_is([ $tokens[1] ]);

    $t->get_ok('/user/email='.$email.'/token/'.$tokens[0]->{name})
        ->status_is(404);

    $t_other_user->reset_session;   # force JWT to be used to authenticate

    $t_other_user->get_ok('/user/me/token', { Authorization => 'Bearer '.$jwts[0] })
        ->status_is(401, 'first token is gone');

    $t_other_user->get_ok('/user/me/token', { Authorization => 'Bearer '.$jwts[1] })
        ->status_is(200, 'second token is still ok')
        ->json_schema_is('UserTokens')
        ->json_cmp_deeply([
            {
                $tokens[1]->%*,
                last_used => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            },
        ]);

    $t_other_user->get_ok('/user/me/token/'.$tokens[0]->{name}, { Authorization => 'Bearer '.$jwts[1] })
        ->status_is(404);

    $t->post_ok('/user/email='.$email.'/revoke')
        ->status_is(204);

    cmp_deeply(
        [ $t->app->db_user_accounts->active->search({ email => $email })
                ->related_resultset('user_session_tokens')
                ->api_only
                ->columns(['name'])
                ->as_epoch('expires')
                ->hri ],
        [
            {
                name => $tokens[1]->{name},
                expires => within_tolerance(less_than => time),
            },
        ],
        'first token has already been deleted; second token still remains, but is expired',
    );

    $t->delete_ok('/user/email='.$email.'/token/'.$tokens[0]->{name})
        ->status_is(404);

    $t->delete_ok('/user/email='.$email.'/token/'.$tokens[1]->{name})
        ->status_is(404);

    $t->get_ok('/user/email='.$email.'/token')
        ->status_is(200)
        ->json_schema_is('UserTokens')
        ->json_is([]);

    $t_other_user->get_ok('/user/me', { Authorization => 'Bearer '.$jwts[0] })
        ->status_is(401, 'first token is gone');

    $t_other_user->get_ok('/user/me', { Authorization => 'Bearer '.$jwts[1] })
        ->status_is(401, 'second token is gone');

    is(
        $t->app->db_user_accounts->active->search({ email => $email })
            ->related_resultset('user_session_tokens')->count,
        0,
        'both tokens are now deleted',
    );
};

warnings(sub {
    memory_cycle_ok($t, 'no leaks in the Test::Conch object');
});

done_testing();
