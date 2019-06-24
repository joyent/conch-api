use v5.26;
use Mojo::Base -strict, -signatures;

use Test::More;
use Test::Warnings;
use Path::Tiny;
use Test::Deep;
use Test::Conch;
use Conch::UUID 'create_uuid_str';

my $t = Test::Conch->new;
$t->load_fixture('conch_user_global_workspace');

$t->authenticate;

my $global_ws_id = $t->app->db_workspaces->get_column('id')->single;
my %workspace_data;
my %users;

subtest 'Workspaces' => sub {
    $t->get_ok('/workspace/notauuid')
        ->status_is(404);

    $t->get_ok('/workspace')
        ->status_is(200)
        ->json_schema_is('WorkspacesAndRoles')
        ->json_is([{
            id          => $global_ws_id,
            name        => 'GLOBAL',
            role        => 'admin',
            description => 'Global workspace. Ancestor of all workspaces.',
            parent_workspace_id => undef,
        }]);

    $workspace_data{conch}[0] = $t->tx->res->json->[0];

    $t->get_ok("/workspace/$global_ws_id")
        ->status_is(200)
        ->json_schema_is('WorkspaceAndRole')
        ->json_is($workspace_data{conch}[0]);

    $t->get_ok('/workspace/GLOBAL')
        ->status_is(200)
        ->json_schema_is('WorkspaceAndRole')
        ->json_is($workspace_data{conch}[0]);

    $t->get_ok('/workspace/'.create_uuid_str())
        ->status_is(404);

    $t->get_ok("/workspace/$global_ws_id/user")
        ->status_is(200)
        ->json_schema_is('WorkspaceUsers')
        ->json_cmp_deeply([
            {
                id    => re(Conch::UUID::UUID_FORMAT),
                name  => $t->CONCH_USER,
                email => $t->CONCH_EMAIL,
                role  => 'admin',
            }
        ]);

    %users = (GLOBAL => $t->tx->res->json);

    is($t->app->db_user_workspace_roles->count, 1,
        'currently one user_workspace_role entry');

    $t->post_ok('/user?send_mail=0',
            json => { email => 'test_user@conch.joyent.us', name => 'test user', password => '123' })
        ->status_is(201, 'created new user "test user"')
        ->location_like(qr!^/user/${\Conch::UUID::UUID_FORMAT}!)
        ->json_schema_is('NewUser')
        ->json_cmp_deeply({
            id => re(Conch::UUID::UUID_FORMAT),
            email => 'test_user@conch.joyent.us',
            name => 'test user',
        })
        ->email_not_sent;

    my $test_user_id = $t->tx->res->json->{id};

    $t->post_ok("/workspace/$global_ws_id/user", json => { role => 'rw' })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', bag(map +{ path => $_, message => re(qr/missing property/i) }, qw(/user_id /email)));

    $t->post_ok("/workspace/$global_ws_id/user", json => { email => 'test_user@conch.joyent.us' })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', [ { path => '/role', message => re(qr/missing property/i) } ]);

    $t->post_ok("/workspace/$global_ws_id/user", json => {
            email => 'test_user@conch.joyent.us',
            role => 'rw',
        })
        ->status_is(204, 'added the user to the GLOBAL workspace')
        ->email_cmp_deeply([
            {
                To => '"test user" <test_user@conch.joyent.us>',
                From => 'noreply@conch.joyent.us',
                Subject => 'Your Conch access has changed',
                body => re(qr/^You have been added to the "GLOBAL" workspace at Joyent Conch with the "rw" role\./m),
            },
            {
                To => '"'.${\$t->CONCH_USER}.'" <'.${\$t->CONCH_EMAIL}.'>',
                From => 'noreply@conch.joyent.us',
                Subject => 'We added a user to your workspace',
                body => re(qr/^${\$t->CONCH_USER} \(${\$t->CONCH_EMAIL}\) has added test user \(test_user\@conch.joyent.us\) to the\R"GLOBAL" workspace at Joyent Conch with the "rw" role\./m),
            },
        ]);

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

    $t->post_ok("/workspace/$global_ws_id/user", json => {
            user_id => $test_user_id,
            role => 'rw',
        })
        ->status_is(204, 'redundant add requests do nothing')
        ->email_not_sent;

    $t->post_ok("/workspace/$global_ws_id/user", json => {
            user_id => $test_user_id,
            email => 'test_user@conch.joyent.us',
            role => 'rw',
        })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', [ { path => '/', message => re(qr/all of the oneof rules/i) } ]);

    is($t->app->db_user_workspace_roles->count, 2,
        'still just two user_workspace_role entries');

    $t->post_ok("/workspace/$global_ws_id/user", json => {
            email => 'test_user@conch.joyent.us',
            role => 'ro',
        })
        ->status_is(409)
        ->json_is({ error => "user test user already has rw access to workspace $global_ws_id: cannot downgrade role to ro" })
        ->email_not_sent;

    $t->get_ok('/user/test_user@conch.joyent.us')
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is('/email' => 'test_user@conch.joyent.us')
        ->json_is('/workspaces' => [{
                id => $global_ws_id,
                name => 'GLOBAL',
                description => 'Global workspace. Ancestor of all workspaces.',
                role => 'rw',
                parent_workspace_id => undef,
            }]);

    $workspace_data{test_user} = $t->tx->res->json->{workspaces};

    $t->get_ok('/user')
        ->status_is(200)
        ->json_schema_is('UsersDetailed')
        ->json_is('/0/email' => $t->CONCH_EMAIL)
        ->json_is('/0/workspaces' => [ $workspace_data{conch}[0] ])
        ->json_is('/1/email' => 'test_user@conch.joyent.us')
        ->json_is('/1/workspaces' => [ $workspace_data{test_user}[0] ]);

    push $users{GLOBAL}->@*, {
        id    => re(Conch::UUID::UUID_FORMAT),
        name  => 'test user',
        email => 'test_user@conch.joyent.us',
        role  => 'rw',
    };

    $t->get_ok("/workspace/$global_ws_id/user")
        ->status_is(200)
        ->json_schema_is('WorkspaceUsers')
        ->json_cmp_deeply($users{GLOBAL});
};

subtest 'Sub-Workspace' => sub {
    $t->get_ok("/workspace/$global_ws_id/child")
        ->status_is(200)
        ->json_schema_is('WorkspacesAndRoles')
        ->json_is([]);

    $t->post_ok("/workspace/$global_ws_id/child")
        ->status_is(400, 'No body is bad request')
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', [ { path => '/', message => re(qr/expected object/i) } ]);

    $t->post_ok("/workspace/$global_ws_id/child", json => { name => $_ })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', [ { path => '/name', message => re(qr/does not match/i) } ])
            foreach 'foo/bar', 'foo.bar';

    $t->post_ok("/workspace/$global_ws_id/child", json => { name => 'GLOBAL' })
        ->status_is(409, 'Cannot create duplicate workspace')
        ->json_is({ error => "workspace 'GLOBAL' already exists" });

    $t->post_ok("/workspace/$global_ws_id/child", json => {
            name        => 'child_ws',
            description => 'one level of workspaces',
        })
        ->status_is(201)
        ->json_schema_is('WorkspaceAndRole')
        ->json_cmp_deeply({
            id          => re(Conch::UUID::UUID_FORMAT),
            name        => 'child_ws',
            description => 'one level of workspaces',
            parent_workspace_id => $global_ws_id,
            role        => 'admin',
            role_via    => $global_ws_id,
        });

    $t->location_is('/workspace/'.(my $child_ws_id = $t->tx->res->json->{id}));
    $workspace_data{conch}[1] = $t->tx->res->json;

    $t->get_ok("/workspace/$global_ws_id/child")
        ->status_is(200)
        ->json_schema_is('WorkspacesAndRoles')
        ->json_is([ $workspace_data{conch}[1] ]);

    $t->get_ok('/workspace/GLOBAL/child')
        ->status_is(200)
        ->json_schema_is('WorkspacesAndRoles')
        ->json_is([ $workspace_data{conch}[1] ]);

    $t->get_ok("/workspace/$child_ws_id")
        ->status_is(200)
        ->json_schema_is('WorkspaceAndRole')
        ->json_is($workspace_data{conch}[1]);

    $t->get_ok('/workspace/child_ws')
        ->status_is(200)
        ->json_schema_is('WorkspaceAndRole')
        ->json_is($workspace_data{conch}[1]);

    $t->post_ok("/workspace/$child_ws_id/child",
            json => { name => 'grandchild_ws', description => 'two levels of subworkspaces' })
        ->status_is(201, 'created a grandchild workspace')
        ->json_schema_is('WorkspaceAndRole')
        ->json_cmp_deeply({
            id          => re(Conch::UUID::UUID_FORMAT),
            name        => 'grandchild_ws',
            description => 'two levels of subworkspaces',
            parent_workspace_id => $child_ws_id,
            role        => 'admin',
            role_via    => $global_ws_id,
        });

    $t->location_is('/workspace/'.(my $grandchild_ws_id = $t->tx->res->json->{id}));
    $workspace_data{conch}[2] = $t->tx->res->json;

    $t->get_ok("/workspace/$global_ws_id/child")
        ->status_is(200)
        ->json_schema_is('WorkspacesAndRoles')
        ->json_cmp_deeply(bag($workspace_data{conch}->@[1,2]));

    $t->get_ok('/workspace')
        ->status_is(200)
        ->json_schema_is('WorkspacesAndRoles')
        ->json_cmp_deeply(bag($workspace_data{conch}->@*));

    $t->get_ok('/user/'.$t->CONCH_EMAIL)
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is('/email' => $t->CONCH_EMAIL)
        ->json_cmp_deeply('/workspaces' => bag($workspace_data{conch}->@*));

    $t->get_ok('/user/me')
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is('/email' => $t->CONCH_EMAIL)
        ->json_cmp_deeply('/workspaces' => bag($workspace_data{conch}->@*));

    $t->get_ok('/user/test_user@conch.joyent.us')
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is('/email' => 'test_user@conch.joyent.us')
        ->json_is('/workspaces' => [
                {
                    id => $global_ws_id,
                    name => 'GLOBAL',
                    description => 'Global workspace. Ancestor of all workspaces.',
                    parent_workspace_id => undef,
                    role => 'rw',
                },
                {
                    id => $child_ws_id,
                    name => 'child_ws',
                    description => 'one level of workspaces',
                    parent_workspace_id => $global_ws_id,
                    role => 'rw',
                    role_via => $global_ws_id,
                },
                {
                    id => $grandchild_ws_id,
                    name => 'grandchild_ws',
                    description => 'two levels of subworkspaces',
                    parent_workspace_id => $child_ws_id,
                    role => 'rw',
                    role_via => $global_ws_id,
                },
            ],
            'new user has access to all workspaces via GLOBAL');

    $workspace_data{test_user} = $t->tx->res->json->{workspaces};

    $t->get_ok('/user')
        ->status_is(200)
        ->json_schema_is('UsersDetailed')
        ->json_is('/0/email' => $t->CONCH_EMAIL)
        ->json_cmp_deeply('/0/workspaces' => bag($workspace_data{conch}->@*))
        ->json_is('/1/email' => 'test_user@conch.joyent.us')
        ->json_cmp_deeply('/1/workspaces' => bag($workspace_data{test_user}->@*));

    $users{child_ws} = [ map +{ $_->%*, role_via => $global_ws_id }, $users{GLOBAL}->@* ];
    $users{grandchild_ws} = [ map +{ $_->%*, role_via => $global_ws_id }, $users{GLOBAL}->@* ];

    $t->get_ok("/workspace/$child_ws_id/user")
        ->status_is(200)
        ->json_schema_is('WorkspaceUsers')
        ->json_cmp_deeply($users{child_ws});

    $t->get_ok("/workspace/$grandchild_ws_id/user")
        ->status_is(200)
        ->json_schema_is('WorkspaceUsers')
        ->json_cmp_deeply($users{grandchild_ws});

    $t->post_ok("/workspace/$grandchild_ws_id/user", json => {
            email => 'test_user@conch.joyent.us',
            role => 'rw',
        })
        ->status_is(204, 'redundant add requests do nothing')
        ->email_not_sent;

    is($t->app->db_user_workspace_roles->count, 2,
        'still just two user_workspace_role entries');

    $t->post_ok("/workspace/$grandchild_ws_id/user", json => {
            email => 'test_user@conch.joyent.us',
            role => 'ro',
        })
        ->status_is(409)
        ->json_is({ error => "user test user already has rw access to workspace $grandchild_ws_id via workspace $global_ws_id: cannot downgrade role to ro" })
        ->email_not_sent;

    $t->post_ok("/workspace/$grandchild_ws_id/user", json => {
            email => 'test_user@conch.joyent.us',
            role => 'admin',
        })
        ->status_is(204, 'can upgrade existing role')
        ->email_cmp_deeply([
            {
                To => '"test user" <test_user@conch.joyent.us>',
                From => 'noreply@conch.joyent.us',
                Subject => 'Your Conch access has changed',
                body => re(qr/^Your access to the "grandchild_ws" workspace at Joyent Conch has been adjusted to "admin"\./m),
            },
            {
                To => '"'.${\$t->CONCH_USER}.'" <'.${\$t->CONCH_EMAIL}.'>',
                From => 'noreply@conch.joyent.us',
                Subject => 'We modified a user\'s access to your workspace',
                body => re(qr/^${\$t->CONCH_USER} \(${\$t->CONCH_EMAIL}\) has modified a user's access to the "grandchild_ws" workspace at Joyent Conch\.\Rtest user \(test_user\@conch.joyent.us\) now has the "admin" role\./m),
            },
        ]);

    is($t->app->db_user_workspace_roles->count, 3,
        'now there are three user_workspace_role entries');

    # now let's try manipulating role entries on the workspace in the middle of the hierarchy

    $t->post_ok("/workspace/$child_ws_id/user", json => {
            email => 'test_user@conch.joyent.us',
            role => 'rw',
        })
        ->status_is(204, 'redundant add requests do nothing')
        ->email_not_sent;

    $t->post_ok("/workspace/$child_ws_id/user", json => {
            email => 'test_user@conch.joyent.us',
            role => 'ro',
        })
        ->status_is(409)
        ->json_is({ error => "user test user already has rw access to workspace $child_ws_id via workspace $global_ws_id: cannot downgrade role to ro" })
        ->email_not_sent;

    is($t->app->db_user_workspace_roles->count, 3,
        'still just three user_workspace_role entries');

    $t->post_ok("/workspace/$child_ws_id/user", json => {
            email => 'test_user@conch.joyent.us',
            role => 'admin',
        })
        ->status_is(204, 'can upgrade existing role that exists in a parent workspace')
        ->email_cmp_deeply([
            {
                To => '"test user" <test_user@conch.joyent.us>',
                From => 'noreply@conch.joyent.us',
                Subject => 'Your Conch access has changed',
                body => re(qr/^Your access to the "child_ws" workspace at Joyent Conch has been adjusted to "admin"\./m),
            },
            {
                To => '"'.${\$t->CONCH_USER}.'" <'.${\$t->CONCH_EMAIL}.'>',
                From => 'noreply@conch.joyent.us',
                Subject => 'We modified a user\'s access to your workspace',
                body => re(qr/^${\$t->CONCH_USER} \(${\$t->CONCH_EMAIL}\) has modified a user's access to the "child_ws" workspace at Joyent Conch\.\Rtest user \(test_user\@conch.joyent.us\) now has the "admin" role\./m),
            },
        ]);


    is($t->app->db_user_workspace_roles->count, 4,
        'now there are four user_workspace_role entries');

    # update our idea of what all the roles should look like:
    $workspace_data{test_user}[1]{role} = 'admin';
    delete $workspace_data{test_user}[1]{role_via};
    $workspace_data{test_user}[2]{role} = 'admin';
    delete $workspace_data{test_user}[2]{role_via};

    $t->get_ok('/user/'.$t->CONCH_EMAIL)
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is('/email' => $t->CONCH_EMAIL)
        ->json_cmp_deeply('/workspaces' => bag($workspace_data{conch}->@*));

    $t->get_ok('/user/test_user@conch.joyent.us')
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is('/email' => 'test_user@conch.joyent.us')
        ->json_cmp_deeply('/workspaces' => bag($workspace_data{test_user}->@*));

    $t->get_ok('/user')
        ->status_is(200)
        ->json_schema_is('UsersDetailed')
        ->json_is('/0/email' => $t->CONCH_EMAIL)
        ->json_cmp_deeply('/0/workspaces' => bag($workspace_data{conch}->@*))
        ->json_is('/1/email' => 'test_user@conch.joyent.us')
        ->json_cmp_deeply('/1/workspaces' => bag($workspace_data{test_user}->@*));

    $t->delete_ok("/workspace/$child_ws_id/user/test_user\@conch.joyent.us")
        ->status_is(204, 'extra roles for user are removed from the sub workspace and its children')
        ->email_cmp_deeply([
            {
                To => '"test user" <test_user@conch.joyent.us>',
                From => 'noreply@conch.joyent.us',
                Subject => 'Your Conch workspaces have been updated.',
                body => re(qr/^You have been removed from the "child_ws" workspace at Joyent Conch\./m),
            },
            {
                To => '"'.${\$t->CONCH_USER}.'" <'.${\$t->CONCH_EMAIL}.'>',
                From => 'noreply@conch.joyent.us',
                Subject => 'We removed a user from your workspace',
                body => re(qr/^${\$t->CONCH_USER} \(${\$t->CONCH_EMAIL}\) has removed test user \(test_user\@conch.joyent.us\) from the\R"child_ws" workspace at Joyent Conch\./m),
            },
        ]);

    $workspace_data{test_user}[1]->@{qw(role role_via)} = ('rw', $global_ws_id);
    $workspace_data{test_user}[2]->@{qw(role role_via)} = ('rw', $global_ws_id);

    $t->get_ok('/user/test_user@conch.joyent.us')
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is('/email' => 'test_user@conch.joyent.us')
        ->json_cmp_deeply('/workspaces' => bag($workspace_data{test_user}->@*));

    $t->delete_ok("/workspace/$child_ws_id/user/test_user\@conch.joyent.us")
        ->status_is(204, 'deleting again is a no-op')
        ->email_not_sent;

    $t->post_ok('/user',
            json => { email => 'untrusted/user@conch.joyent.us', name => 'me', password => '123' })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', [ { path => '/email', message => re(qr/does not match/i) } ])
        ->email_not_sent;

    $t->post_ok('/user',
            json => { email => 'untrusted_user@conch.joyent.us', name => 'me', password => '123' })
        ->status_is(400)
        ->json_is({ error => 'user name "me" is prohibited' })
        ->email_not_sent;

    $t->post_ok('/user?send_mail=0',
            json => { email => 'untrusted_user@conch.joyent.us', name => 'untrusted user', password => '123' })
        ->status_is(201, 'created new untrusted user')
        ->location_like(qr!^/user/${\Conch::UUID::UUID_FORMAT}!)
        ->json_schema_is('NewUser')
        ->email_not_sent;

    $t->post_ok('/workspace/child_ws/user', json => {
            email => 'untrusted_user@conch.joyent.us',
            role => 'ro',
        })
        ->status_is(204, 'added the user to the child workspace')
        ->email_cmp_deeply([
            {
                To => '"untrusted user" <untrusted_user@conch.joyent.us>',
                From => 'noreply@conch.joyent.us',
                Subject => 'Your Conch access has changed',
                body => re(qr/^You have been added to the "child_ws" workspace at Joyent Conch with the "ro" role\./m),
            },
            {
                To => '"'.${\$t->CONCH_USER}.'" <'.${\$t->CONCH_EMAIL}.'>',
                From => 'noreply@conch.joyent.us',
                Subject => 'We added a user to your workspace',
                body => re(qr/^${\$t->CONCH_USER} \(${\$t->CONCH_EMAIL}\) has added untrusted user \(untrusted_user\@conch.joyent.us\) to the\R"child_ws" workspace at Joyent Conch with the "ro" role\./m),
            },
        ]);

    $t->get_ok('/workspace/GLOBAL/user')
        ->status_is(200)
        ->json_schema_is('WorkspaceUsers')
        ->json_cmp_deeply($users{GLOBAL});

    push $users{child_ws}->@*, {
        id    => re(Conch::UUID::UUID_FORMAT),
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
        ->json_cmp_deeply($users{child_ws});

    $t->get_ok('/workspace/grandchild_ws/user')
        ->status_is(200)
        ->json_schema_is('WorkspaceUsers')
        ->json_cmp_deeply($users{grandchild_ws});

    $workspace_data{untrusted_user} = [
        {
            $workspace_data{conch}[1]->%{qw(id name description parent_workspace_id)},
            role => 'ro',
        },
        {
            $workspace_data{conch}[2]->%{qw(id name description parent_workspace_id)},
            role => 'ro',
            role_via => $child_ws_id,
        },
    ];

    $t->get_ok('/user')
        ->status_is(200)
        ->json_schema_is('UsersDetailed')
        ->json_is('/0/email' => $t->CONCH_EMAIL)
        ->json_cmp_deeply('/0/workspaces' => bag($workspace_data{conch}->@*))
        ->json_is('/1/email' => 'test_user@conch.joyent.us')
        ->json_cmp_deeply('/1/workspaces' => bag($workspace_data{test_user}->@*))
        ->json_is('/2/email' => 'untrusted_user@conch.joyent.us')
        ->json_cmp_deeply('/2/workspaces' => bag($workspace_data{untrusted_user}->@*));


    my $untrusted = Test::Conch->new(pg => $t->pg);
    $untrusted->authenticate(email => 'untrusted_user@conch.joyent.us', password => '123');

    # this user cannot be shown the GLOBAL workspace or its id
    undef $workspace_data{untrusted_user}[0]{parent_workspace_id};
    delete $users{GLOBAL};

    $untrusted->get_ok('/workspace/GLOBAL')
        ->status_is(403);

    $untrusted->get_ok('/workspace/child_ws')
        ->status_is(200)
        ->json_schema_is('WorkspaceAndRole')
        ->json_is($workspace_data{untrusted_user}[0]);

    $untrusted->get_ok('/workspace/grandchild_ws')
        ->status_is(200)
        ->json_schema_is('WorkspaceAndRole')
        ->json_is($workspace_data{untrusted_user}[1]);

    $untrusted->get_ok('/user')
        ->status_is(403);

    $untrusted->get_ok('/workspace/GLOBAL/user')
        ->status_is(403);

    $untrusted->get_ok('/workspace/child_ws/user')
        ->status_is(403);

    $t->post_ok('/workspace/child_ws/user', json => {
            email => 'untrusted_user@conch.joyent.us',
            role => 'admin',
        })
        ->status_is(204, 'can upgrade existing role that exists in this workspace')
        ->email_cmp_deeply([
            {
                To => '"untrusted user" <untrusted_user@conch.joyent.us>',
                From => 'noreply@conch.joyent.us',
                Subject => 'Your Conch access has changed',
                body => re(qr/^Your access to the "child_ws" workspace at Joyent Conch has been adjusted to "admin"\./m),
            },
            {
                To => '"'.${\$t->CONCH_USER}.'" <'.${\$t->CONCH_EMAIL}.'>',
                From => 'noreply@conch.joyent.us',
                Subject => 'We modified a user\'s access to your workspace',
                body => re(qr/^${\$t->CONCH_USER} \(${\$t->CONCH_EMAIL}\) has modified a user's access to the "child_ws" workspace at Joyent Conch\.\Runtrusted user \(untrusted_user\@conch.joyent.us\) now has the "admin" role\./m),
            },
        ]);

    $users{child_ws}[-1]{role} = 'admin';
    $users{grandchild_ws}[-1]{role} = 'admin';

    $t->get_ok('/workspace/child_ws/user')
        ->status_is(200)
        ->json_schema_is('WorkspaceUsers')
        ->json_cmp_deeply($users{child_ws});

    $untrusted->get_ok('/workspace/GLOBAL/user')
        ->status_is(403);

    $untrusted->get_ok('/workspace/child_ws/user')
        ->status_is(200)
        ->json_schema_is('WorkspaceUsers')
        ->json_cmp_deeply($users{child_ws});

    $untrusted->get_ok('/workspace/grandchild_ws/user')
        ->status_is(200)
        ->json_schema_is('WorkspaceUsers')
        ->json_cmp_deeply($users{grandchild_ws});
};

subtest 'Roles' => sub {
    subtest 'Read-only' => sub {
        my $ro_user = $t->load_fixture('ro_user_global_workspace')->user_account;
        $t->authenticate(email => $ro_user->email);

        $t->get_ok('/workspace')
            ->status_is(200)
            ->json_schema_is('WorkspacesAndRoles')
            ->json_is('/0/name' => 'GLOBAL');

        $t->post_ok("/workspace/$global_ws_id/child",
                json => { name => 'test', description => 'also test' })
            ->status_is(403);

        $t->post_ok("/workspace/$global_ws_id/rack", json => { id => create_uuid_str() })
            ->status_is(403);

        $t->post_ok("/workspace/$global_ws_id/user",
                json => { user => 'another@wat.wat', role => 'ro' })
            ->status_is(403);

        $t->get_ok("/workspace/$global_ws_id/user")
            ->status_is(403);

        $t->post_ok('/logout')
            ->status_is(204);
    };

    subtest 'Read-write' => sub {
        my $rw_user = $t->load_fixture('rw_user_global_workspace')->user_account;
        $t->authenticate(email => $rw_user->email);

        $t->get_ok('/workspace')
            ->status_is(200)
            ->json_schema_is('WorkspacesAndRoles')
            ->json_is('/0/name' => 'GLOBAL');

        $t->post_ok("/workspace/$global_ws_id/child",
                json => { name => 'test', description => 'also test' })
            ->status_is(403);

        $t->post_ok("/workspace/$global_ws_id/user",
                json => { user => 'another@wat.wat', role => 'ro' })
            ->status_is(403);

        $t->get_ok("/workspace/$global_ws_id/user")
            ->status_is(403);
    };
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
