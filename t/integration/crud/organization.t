use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;
use Conch::UUID 'create_uuid_str';

my $t = Test::Conch->new;
my $super_user = $t->load_fixture('super_user');

$t->authenticate;

$t->get_ok('/organization')
    ->status_is(200)
    ->json_schema_is('Organizations')
    ->json_is([]);

$t->post_ok('/organization', json => { name => $_, admins => [ { user_id => create_uuid_str() } ] })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/name', message => re(qr/does not match/i) } ])
        foreach '', 'foo/bar', 'foo.bar';

$t->post_ok('/organization', json => { name => 'my first organization', admins => [ {} ] })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', bag(map +{ path => '/admins/0/'.$_, message => re(qr/missing property/i) }, qw(user_id email)));

$t->post_ok('/organization', json => { name => 'my first organization' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/admins', message => re(qr/missing property/i) } ] );

$t->post_ok('/organization', json => {
        name => 'my first organization',
        admins => [ { user_id => create_uuid_str(), email => 'foo@bar.com' } ],
    })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/admins/0', message => re(qr/all of the oneof rules/i) } ] );

$t->post_ok('/organization', json => { name => 'my first organization', admins => [ { user_id => create_uuid_str() } ] })
    ->status_is(409)
    ->json_cmp_deeply({ error => re(qr/^unrecognized user_id ${\Conch::UUID::UUID_FORMAT}$/) });

$t->post_ok('/organization', json => { name => 'my first organization', admins => [ { email => 'foo@bar.com' } ] })
    ->status_is(409)
    ->json_is({ error => 'unrecognized email foo@bar.com' });

$t->post_ok('/organization', json => {
        name => 'my first organization',
        admins => [ { user_id => create_uuid_str() }, { email => 'foo@bar.com' } ],
    })
    ->status_is(409)
    ->json_cmp_deeply({ error => re(qr/^unrecognized user_id ${\Conch::UUID::UUID_FORMAT}, email foo\@bar.com$/) });

my $admin_user = $t->generate_fixtures('user_account');
$t->post_ok('/organization', json => { name => 'my first organization', admins => [ { user_id => $admin_user->id } ] })
    ->status_is(303)
    ->location_like(qr!^/organization/${\Conch::UUID::UUID_FORMAT}$!)
    ->log_info_like(qr/^created organization ${\Conch::UUID::UUID_FORMAT} \(my first organization\)$/);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('Organization')
    ->json_cmp_deeply({
        id => re(Conch::UUID::UUID_FORMAT),
        name => 'my first organization',
        description => undef,
        created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        admins => [
            { map +($_ => $admin_user->$_), qw(id name email) },
        ],
        workspaces => [],
    });
my $organization = $t->tx->res->json;

$t->get_ok('/organization/my first organization')
    ->status_is(200)
    ->json_schema_is('Organization')
    ->json_is($organization);

$t->get_ok('/organization')
    ->status_is(200)
    ->json_schema_is('Organizations')
    ->json_is([ $organization ]);

$t->delete_ok('/organization/my first organization/user/'.$admin_user->email)
    ->status_is(409)
    ->json_is({ error => 'organizations must have an admin' });

$t->post_ok('/organization', json => { name => 'my first organization', admins => [ { email => $admin_user->email } ] })
    ->status_is(409)
    ->json_is({ error => 'an organization already exists with that name' });

$t->post_ok('/organization', json => { name => 'our second organization', description => 'funky', admins => [ { email => $admin_user->email } ] })
    ->status_is(303)
    ->location_like(qr!^/organization/${\Conch::UUID::UUID_FORMAT}$!)
    ->log_info_like(qr/^created organization ${\Conch::UUID::UUID_FORMAT} \(our second organization\)$/);

$t->get_ok('/organization')
    ->status_is(200)
    ->json_schema_is('Organizations')
    ->json_cmp_deeply([
        $organization,
        {
            id => re(Conch::UUID::UUID_FORMAT),
            name => 'our second organization',
            description => 'funky',
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            admins => [
                { map +($_ => $admin_user->$_), qw(id name email) },
            ],
            workspaces => [],
        },
    ]);
my $organization2 = $t->tx->res->json->[1];

my $new_user = $t->generate_fixtures('user_account');

my $t2 = Test::Conch->new(pg => $t->pg);
$t2->authenticate(email => $new_user->email);

$t2->post_ok('/organization', json => { name => 'another organization' })
    ->status_is(403);

$t2->get_ok('/organization')
    ->status_is(200)
    ->json_schema_is('Organizations')
    ->json_is([]);

$t2->get_ok('/organization/'.$organization->{id})
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for organization '.$organization->{id});

$t2->get_ok('/organization/my first organization')
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for organization my first organization');

$t2->delete_ok('/organization/foo')
    ->status_is(404);

$t2->delete_ok('/organization/my first organization')
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for organization my first organization');


$t->get_ok('/organization/my first organization/user')
    ->status_is(200)
    ->json_schema_is('OrganizationUsers')
    ->json_is([
        { (map +($_ => $admin_user->$_), qw(id name email)), role => 'admin' },
    ]);

$t->post_ok('/organization/'.$organization->{id}.'/user', json => { role => 'ro' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', bag(map +{ path => $_, message => re(qr/missing property/i) }, qw(/user_id /email)));

$t->post_ok('/organization/my first organization/user', json => { email => $new_user->email })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/role', message => re(qr/missing property/i) } ]);

$t->post_ok('/organization/my first organization/user', json => {
        email => $new_user->email,
        role => 'ro',
    })
    ->status_is(204)
    ->log_info_is('Added user '.$new_user->id.' ('.$new_user->name.') to organization my first organization with the ro role')
    ->email_cmp_deeply([
        {
            To => '"'.$new_user->name.'" <'.$new_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch access has changed',
            body => re(qr/^You have been added to the "my first organization" organization at Joyent Conch with the "ro" role\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'We added a user to your organization',
            body => re(qr/^${\$super_user->name} \(${\$super_user->email}\) added ${\$new_user->name} \(${\$new_user->email}\) to the\R"my first organization" organization at Joyent Conch with the "ro" role\./m),
        },
    ]);

$t->get_ok('/organization/my first organization/user')
    ->status_is(200)
    ->json_schema_is('OrganizationUsers')
    ->json_is([
        { (map +($_ => $admin_user->$_), qw(id name email)), role => 'admin' },
        { (map +($_ => $new_user->$_), qw(id name email)), role => 'ro' },
    ]);

# non-admin user can only see the organization(s) he is a member of
$t2->get_ok('/organization')
    ->status_is(200)
    ->json_schema_is('Organizations')
    ->json_is([ $organization ]);

$t->get_ok('/organization/my first organization')
    ->status_is(200)
    ->json_schema_is('Organization')
    ->json_is($organization);

$t2->delete_ok('/organization/my first organization')
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for organization my first organization');

$t2->get_ok('/organization/my first organization/user')
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for organization my first organization');

my $new_user2 = $t->generate_fixtures('user_account');
$t2->post_ok('/organization/'.$organization->{id}.'/user', json => {
        email => $new_user2->email,
        role => 'ro',
    })
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for organization '.$organization->{id});

$t2->delete_ok('/organization/my first organization/user/'.$admin_user->email)
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for organization my first organization');


$t->post_ok('/organization/my first organization/user', json => {
        email => $new_user->email,
        role => 'rw',
    })
    ->status_is(204)
    ->log_info_is('Updated access for user '.$new_user->id.' ('.$new_user->name.') in organization my first organization to the rw role')
    ->email_cmp_deeply([
        {
            To => '"'.$new_user->name.'" <'.$new_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch access has changed',
            body => re(qr/^Your access to the "my first organization" organization at Joyent Conch has been adjusted to "rw"\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'We modified a user\'s access to your organization',
            body => re(qr/^${\$super_user->name} \(${\$super_user->email}\) modified a user's access to your organization "my first organization" at Joyent Conch\.\R${\$new_user->name} \(${\$new_user->email}\) now has the "rw" role\./m),
        },
    ]);

$t->get_ok('/organization/my first organization/user')
    ->status_is(200)
    ->json_schema_is('OrganizationUsers')
    ->json_is([
        { (map +($_ => $admin_user->$_), qw(id name email)), role => 'admin' },
        { (map +($_ => $new_user->$_), qw(id name email)), role => 'rw' },
    ]);

$t2->get_ok('/organization/my first organization/user')
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for organization my first organization');

$t2->post_ok('/organization/'.$organization->{id}.'/user', json => {
        email => $new_user2->email,
        role => 'ro',
    })
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for organization '.$organization->{id});

$t2->delete_ok('/organization/my first organization/user/'.$admin_user->email)
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for organization my first organization');


$t->post_ok('/organization/'.$organization->{id}.'/user', json => {
        email => $new_user->email,
        role => 'admin',
    })
    ->status_is(204)
    ->log_info_is('Updated access for user '.$new_user->id.' ('.$new_user->name.') in organization '.$organization->{id}.' to the admin role')
    ->email_cmp_deeply([
        {
            To => '"'.$new_user->name.'" <'.$new_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch access has changed',
            body => re(qr/^Your access to the "my first organization" organization at Joyent Conch has been adjusted to "admin"\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'We modified a user\'s access to your organization',
            body => re(qr/^${\$super_user->name} \(${\$super_user->email}\) modified a user's access to your organization "my first organization" at Joyent Conch\.\R${\$new_user->name} \(${\$new_user->email}\) now has the "admin" role\./m),
        }
    ]);

$t->get_ok('/organization/my first organization/user')
    ->status_is(200)
    ->json_schema_is('OrganizationUsers')
    ->json_is([
        { (map +($_ => $admin_user->$_), qw(id name email)), role => 'admin' },
        { (map +($_ => $new_user->$_), qw(id name email)), role => 'admin' },
    ]);
push $organization->{admins}->@*, +{ $t->tx->res->json->[1]->%{qw(id name email)} };

$t2->get_ok('/organization/my first organization/user')
    ->status_is(200)
    ->json_schema_is('OrganizationUsers')
    ->json_is([
        { (map +($_ => $admin_user->$_), qw(id name email)), role => 'admin' },
        { (map +($_ => $new_user->$_), qw(id name email)), role => 'admin' },
    ]);

$t2->post_ok('/organization/'.$organization->{id}.'/user', json => {
        email => $new_user2->email,
        role => 'ro',
    })
    ->status_is(204)
    ->log_info_is('Added user '.$new_user2->id.' ('.$new_user2->name.') to organization '.$organization->{id}.' with the ro role')
    ->email_cmp_deeply([
        {
            To => '"'.$new_user2->name.'" <'.$new_user2->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch access has changed',
            body => re(qr/^You have been added to the "my first organization" organization at Joyent Conch with the "ro" role\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>, "'.$new_user->name.'" <'.$new_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'We added a user to your organization',
            body => re(qr/^${\$new_user->name} \(${\$new_user->email}\) added ${\$new_user2->name} \(${\$new_user2->email}\) to the\R"my first organization" organization at Joyent Conch with the "ro" role\./m),
        },
    ]);

$t2->get_ok('/organization/my first organization/user')
    ->status_is(200)
    ->json_schema_is('OrganizationUsers')
    ->json_is([
        { (map +($_ => $admin_user->$_), qw(id name email)), role => 'admin' },
        { (map +($_ => $new_user->$_), qw(id name email)), role => 'admin' },
        { (map +($_ => $new_user2->$_), qw(id name email)), role => 'ro' },
    ]);

$t2->delete_ok('/organization/my first organization/user/'.$new_user2->email)
    ->status_is(204)
    ->log_info_is('removing user '.$new_user2->id.' ('.$new_user2->name.') from organization my first organization')
    ->email_cmp_deeply([
        {
            To => '"'.$new_user2->name.'" <'.$new_user2->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch organizations have been updated',
            body => re(qr/^You have been removed from the "my first organization" organization at Joyent Conch\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>, "'.$new_user->name.'" <'.$new_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'We removed a user from your organization',
            body => re(qr/^${\$new_user->name} \(${\$new_user->email}\) removed ${\$new_user2->name} \(${\$new_user2->email}\) from the\R"my first organization" organization at Joyent Conch\./m),
        },
    ]);

$t2->get_ok('/organization/my first organization/user')
    ->status_is(200)
    ->json_schema_is('OrganizationUsers')
    ->json_is([
        { (map +($_ => $admin_user->$_), qw(id name email)), role => 'admin' },
        { (map +($_ => $new_user->$_), qw(id name email)), role => 'admin' },
    ]);

$admin_user->discard_changes;
$t->delete_ok('/user/'.$admin_user->id)
    ->status_is(409)
    ->json_is({
        error => 'user is the only admin of the "our second organization" organization ('.$organization2->{id}.')',
        user => { map +($_ => $admin_user->$_), qw(id email name created deactivated) },
    });


my $global_ws = $t->load_fixture('global_workspace');
my $sub_ws = $t->generate_fixtures('workspace', { parent_workspace_id => $global_ws->id, name => 'sub ws' });

$t->get_ok('/workspace/'.$sub_ws->id.'/organization')
    ->status_is(200)
    ->json_schema_is('WorkspaceOrganizations')
    ->json_is([]);

$t->post_ok('/workspace/'.$sub_ws->id.'/organization', json => { role => 'ro' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/organization_id', message => re(qr/missing property/i) } ]);

$t->post_ok('/workspace/'.$sub_ws->id.'/organization', json => { organization_id => $organization->{id} })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/role', message => re(qr/missing property/i) } ]);

$t2->get_ok('/workspace/'.$sub_ws->id.'/organization')
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for workspace '.$sub_ws->id);

$t2->post_ok('/workspace/'.$sub_ws->id.'/organization', json => {
        organization_id => $organization->{id},
        role => 'ro',
    })
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for workspace '.$sub_ws->id);

$t->post_ok('/workspace/'.$sub_ws->id.'/organization', json => {
        organization_id => $organization->{id},
        role => 'ro',
    })
    ->status_is(204)
    ->email_cmp_deeply([
        {
            To => '"'.$admin_user->name.'" <'.$admin_user->email.'>, "'.$new_user->name.'" <'.$new_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch access has changed',
            body => re(qr/^Your "my first organization" organization has been added to the\R"${\$sub_ws->name}" workspace at Joyent Conch with the "ro" role\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'We added an organization to your workspace',
            body => re(qr/^${\$super_user->name} \(${\$super_user->email}\) added the "my first organization" organization to the\R"${\$sub_ws->name}" workspace at Joyent Conch with the "ro" role\./m),
        },
    ]);

$t->get_ok('/workspace/'.$sub_ws->id.'/organization')
    ->status_is(200)
    ->json_schema_is('WorkspaceOrganizations')
    ->json_is([
        {
            $organization->%{qw(id name description)},
            role => 'ro',
            admins => [
                { map +($_ => $admin_user->$_), qw(id name email) },
                { map +($_ => $new_user->$_), qw(id name email) },
            ],
        },
    ]);

push $organization->{workspaces}->@*, +{ (map +($_ => $sub_ws->$_), qw(id parent_workspace_id name description)), role => 'ro' };

$t->get_ok('/organization/my first organization')
    ->status_is(200)
    ->json_schema_is('Organization')
    ->json_is($organization);

$t->get_ok('/organization')
    ->status_is(200)
    ->json_schema_is('Organizations')
    ->json_is([ $organization, $organization2 ]);

$t2->get_ok('/organization/my first organization')
    ->status_is(200)
    ->json_schema_is('Organization')
    ->json_is({
        $organization->%*,
        workspaces => [
            {
                (map +($_ => $sub_ws->$_), qw(id name description)),
                parent_workspace_id => undef, # user does not have the role to see GLOBAL
                role => 'ro',
            },
        ],
    });

$t2->get_ok('/organization')
    ->status_is(200)
    ->json_schema_is('Organizations')
    ->json_is([
        {
            $organization->%*,
            workspaces => [
                {
                    (map +($_ => $sub_ws->$_), qw(id name description)),
                    parent_workspace_id => undef, # user does not have the role to see GLOBAL
                    role => 'ro',
                },
            ],
        },
        # user is not a member of organization2
    ]);

$t->get_ok('/user/'.$admin_user->email)
    ->status_is(200)
    ->json_schema_is('UserDetailed')
    ->json_cmp_deeply(superhashof({
        id => $admin_user->id,
        organizations => [
            { $organization->%{qw(id name description)}, role => 'admin' },
            { $organization2->%{qw(id name description)}, role => 'admin' },
        ],
        workspaces => [
            {
                (map +($_ => $sub_ws->$_), qw(id name description parent_workspace_id)),
                role => 'ro',
                role_via_organization_id => $organization->{id},
            },
        ],
    }));

$t->get_ok('/user/'.$new_user->email)
    ->status_is(200)
    ->json_schema_is('UserDetailed')
    ->json_cmp_deeply(superhashof({
        id => $new_user->id,
        organizations => [
            { $organization->%{qw(id name description)}, role => 'admin' },
        ],
        workspaces => [
            {
                (map +($_ => $sub_ws->$_), qw(id name description parent_workspace_id)),
                role => 'ro',
                role_via_organization_id => $organization->{id},
            },
        ],
    }));

$t2->get_ok('/user/me')
    ->status_is(200)
    ->json_schema_is('UserDetailed')
    ->json_cmp_deeply(superhashof({
        id => $new_user->id,
        organizations => [
            { $organization->%{qw(id name description)}, role => 'admin' },
        ],
        workspaces => [
            {
                (map +($_ => $sub_ws->$_), qw(id name description)),
                parent_workspace_id => undef, # user does not have the role to see GLOBAL
                role => 'ro',
                role_via_organization_id => $organization->{id},
            },
        ],
    }));

my $grandchild_ws = $t->generate_fixtures('workspace', { parent_workspace_id => $sub_ws->id, name => 'grandchild ws' });

push $organization->{workspaces}->@*, +{ (map +($_ => $grandchild_ws->$_), qw(id parent_workspace_id name description)), role => 'ro', role_via_workspace_id => $sub_ws->id };

$t->get_ok('/workspace/'.$grandchild_ws->id.'/organization')
    ->status_is(200)
    ->json_schema_is('WorkspaceOrganizations')
    ->json_is([
        {
            $organization->%{qw(id name description)},
            role => 'ro',
            role_via_workspace_id => $sub_ws->id,
            admins => [
                { map +($_ => $admin_user->$_), qw(id name email) },
                { map +($_ => $new_user->$_), qw(id name email) },
            ],
        },
    ]);

$t->get_ok('/user/'.$admin_user->email)
    ->status_is(200)
    ->json_schema_is('UserDetailed')
    ->json_cmp_deeply(superhashof({
        id => $admin_user->id,
        organizations => [
            { $organization->%{qw(id name description)}, role => 'admin' },
            { $organization2->%{qw(id name description)}, role => 'admin' },
        ],
        workspaces => [
            {
                (map +($_ => $sub_ws->$_), qw(id name description parent_workspace_id)),
                role => 'ro',
                role_via_organization_id => $organization->{id},
            },
            {
                (map +($_ => $grandchild_ws->$_), qw(id name description parent_workspace_id)),
                role => 'ro',
                role_via_organization_id => $organization->{id},
                role_via_workspace_id => $sub_ws->id,
            },
        ],
    }));

$t->get_ok('/user/'.$new_user->email)
    ->status_is(200)
    ->json_schema_is('UserDetailed')
    ->json_cmp_deeply(superhashof({
        id => $new_user->id,
        organizations => [
            { $organization->%{qw(id name description)}, role => 'admin' },
        ],
        workspaces => [
            {
                (map +($_ => $sub_ws->$_), qw(id name description parent_workspace_id)),
                role => 'ro',
                role_via_organization_id => $organization->{id},
            },
            {
                (map +($_ => $grandchild_ws->$_), qw(id name description parent_workspace_id)),
                role => 'ro',
                role_via_organization_id => $organization->{id},
                role_via_workspace_id => $sub_ws->id,
            },
        ],
    }));

$t2->get_ok('/user/me')
    ->status_is(200)
    ->json_schema_is('UserDetailed')
    ->json_cmp_deeply(superhashof({
        id => $new_user->id,
        organizations => [
            { $organization->%{qw(id name description)}, role => 'admin' },
        ],
        workspaces => [
            {
                (map +($_ => $sub_ws->$_), qw(id name description)),
                parent_workspace_id => undef, # user does not have the role to see GLOBAL
                role => 'ro',
                role_via_organization_id => $organization->{id},
            },
            {
                (map +($_ => $grandchild_ws->$_), qw(id name description parent_workspace_id)),
                role => 'ro',
                role_via_organization_id => $organization->{id},
                role_via_workspace_id => $sub_ws->id,
            },
        ],
    }));

$t->get_ok('/workspace/'.$sub_ws->id.'/user')
    ->status_is(200)
    ->json_schema_is('WorkspaceUsers')
    ->json_is([
        {
            (map +($_ => $admin_user->$_), qw(id name email)),
            role => 'ro',
            role_via_organization_id => $organization->{id},
        },
        {
            (map +($_ => $new_user->$_), qw(id name email)),
            role => 'ro',
            role_via_organization_id => $organization->{id},
        },
    ]);

$t->get_ok('/workspace/'.$grandchild_ws->id.'/user')
    ->status_is(200)
    ->json_schema_is('WorkspaceUsers')
    ->json_is([
        {
            (map +($_ => $admin_user->$_), qw(id name email)),
            role => 'ro',
            role_via_workspace_id => $sub_ws->id,
            role_via_organization_id => $organization->{id},
        },
        {
            (map +($_ => $new_user->$_), qw(id name email)),
            role => 'ro',
            role_via_workspace_id => $sub_ws->id,
            role_via_organization_id => $organization->{id},
        },
    ]);

$t2->get_ok('/workspace')
    ->status_is(200)
    ->json_schema_is('WorkspacesAndRoles')
    ->json_is([
        # $new_user cannot see GLOBAL
        {
            (map +($_ => $sub_ws->$_), qw(id name description)),
            parent_workspace_id => undef,
            role => 'ro',
            role_via_organization_id => $organization->{id},
        },
        {
            (map +($_ => $grandchild_ws->$_), qw(id name description parent_workspace_id)),
            role => 'ro',
            role_via_workspace_id => $sub_ws->id,
            role_via_organization_id => $organization->{id},
        },
    ]);

$t->post_ok('/workspace/'.$sub_ws->id.'/organization', json => {
        organization_id => $organization->{id},
        role => 'rw',
    })
    ->status_is(204)
    ->email_cmp_deeply([
        {
            To => '"'.$admin_user->name.'" <'.$admin_user->email.'>, "'.$new_user->name.'" <'.$new_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch access has changed',
            body => re(qr/^Your access to the "${\$sub_ws->name}" workspace at Joyent Conch\Rvia the "my first organization" organization has been adjusted to the "rw" role\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'We modified an organization\'s access to your workspace',
            body => re(qr/^${\$super_user->name} \(${\$super_user->email}\) modified the "my first organization" organization's\Raccess to the "${\$sub_ws->name}" workspace at Joyent Conch to the "rw" role\./m),
        },
    ]);

$t->get_ok('/workspace/'.$sub_ws->id.'/organization')
    ->status_is(200)
    ->json_schema_is('WorkspaceOrganizations')
    ->json_is([
        {
            $organization->%{qw(id name description)},
            role => 'rw',
            admins => [
                { map +($_ => $admin_user->$_), qw(id name email) },
                { map +($_ => $new_user->$_), qw(id name email) },
            ],
        },
    ]);

$_->{role} = 'rw' foreach $organization->{workspaces}->@*;

$t->get_ok('/organization/my first organization')
    ->status_is(200)
    ->json_schema_is('Organization')
    ->json_is($organization);

$t->get_ok('/organization')
    ->status_is(200)
    ->json_schema_is('Organizations')
    ->json_is([ $organization, $organization2 ]);

$t->post_ok('/workspace/'.$sub_ws->id.'/organization', json => {
        organization_id => $organization->{id},
        role => 'rw',
    })
    ->status_is(204)
    ->log_debug_is('organization "my first organization" already has rw access to workspace '.$sub_ws->id.': nothing to do')
    ->email_not_sent;

$t->post_ok('/workspace/'.$grandchild_ws->id.'/organization', json => {
        organization_id => $organization->{id},
        role => 'rw',
    })
    ->status_is(204)
    ->log_debug_is('organization "my first organization" already has rw access to workspace '.$grandchild_ws->id.' via workspace '.$sub_ws->id.': nothing to do')
    ->email_not_sent;

$t->post_ok('/workspace/'.$sub_ws->id.'/organization', json => {
        organization_id => $organization->{id},
        role => 'ro',
    })
    ->status_is(409)
    ->json_is({ error => 'organization "my first organization" already has rw access to workspace '.$sub_ws->id.': cannot downgrade role to ro' })
    ->email_not_sent;

$t->post_ok('/workspace/'.$grandchild_ws->id.'/organization', json => {
        organization_id => $organization->{id},
        role => 'ro',
    })
    ->status_is(409)
    ->json_is({ error => 'organization "my first organization" already has rw access to workspace '.$grandchild_ws->id.' via workspace '.$sub_ws->id.': cannot downgrade role to ro' })
    ->email_not_sent;

$t->post_ok('/workspace/'.$sub_ws->id.'/user', json => {
        user_id => $new_user->id,
        role => 'rw',
    })
    ->log_debug_is('user '.$new_user->name.' already has rw access to workspace '.$sub_ws->id.' via organization '.$organization->{id}.': nothing to do')
    ->status_is(204)
    ->email_not_sent;

$t->post_ok('/workspace/'.$grandchild_ws->id.'/user', json => {
        user_id => $new_user->id,
        role => 'rw',
    })
    ->log_debug_is('user '.$new_user->name.' already has rw access to workspace '.$grandchild_ws->id.' via workspace '.$sub_ws->id.' and organization '.$organization->{id}.': nothing to do')
    ->status_is(204)
    ->email_not_sent;

$t->post_ok('/workspace/'.$sub_ws->id.'/user', json => {
        user_id => $new_user->id,
        role => 'ro',
    })
    ->status_is(409)
    ->json_is({ error => 'user '.$new_user->name.' already has rw access to workspace '.$sub_ws->id.' via organization '.$organization->{id}.': cannot downgrade role to ro' })
    ->email_not_sent;

$t->post_ok('/workspace/'.$grandchild_ws->id.'/user', json => {
        user_id => $new_user->id,
        role => 'ro',
    })
    ->status_is(409)
    ->json_is({ error => 'user '.$new_user->name.' already has rw access to workspace '.$grandchild_ws->id.' via workspace '.$sub_ws->id.' and organization '.$organization->{id}.': cannot downgrade role to ro' })
    ->email_not_sent;

$t2->delete_ok('/workspace/grandchild ws/organization/my first organization')
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for workspace grandchild ws');


my $t_admin_user = Test::Conch->new(pg => $t->pg);
$t_admin_user->authenticate(email => $admin_user->email);

$t_admin_user->delete_ok('/workspace/'.$grandchild_ws->id.'/organization/'.$organization->{id})
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for workspace '.$grandchild_ws->id);

$t_admin_user->delete_ok('/workspace/'.$sub_ws->id.'/organization/'.$organization->{id})
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for workspace '.$sub_ws->id);

$t->delete_ok('/workspace/'.$grandchild_ws->id.'/organization/'.$organization->{id})
    ->status_is(204)
    ->email_not_sent;


$t->get_ok('/workspace/'.$grandchild_ws->id.'/organization')
    ->status_is(200)
    ->json_schema_is('WorkspaceOrganizations')
    ->json_is([
        {
            $organization->%{qw(id name description)},
            role => 'rw',
            role_via_workspace_id => $sub_ws->id,
            admins => [
                { map +($_ => $admin_user->$_), qw(id name email) },
                { map +($_ => $new_user->$_), qw(id name email) },
            ],
        },
    ]);

$t->post_ok('/workspace/'.$grandchild_ws->id.'/organization', json => {
        organization_id => $organization->{id},
        role => 'admin',
    })
    ->status_is(204)
    ->email_cmp_deeply([
        {
            To => '"'.$admin_user->name.'" <'.$admin_user->email.'>, "'.$new_user->name.'" <'.$new_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch access has changed',
            body => re(qr/^Your access to the "${\$grandchild_ws->name}" workspace at Joyent Conch\Rvia the "my first organization" organization has been adjusted to the "admin" role\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'We modified an organization\'s access to your workspace',
            body => re(qr/^${\$super_user->name} \(${\$super_user->email}\) modified the "my first organization" organization's\Raccess to the "${\$grandchild_ws->name}" workspace at Joyent Conch to the "admin" role\./m),
        },
    ]);

$t->get_ok('/workspace/'.$grandchild_ws->id.'/organization')
    ->status_is(200)
    ->json_schema_is('WorkspaceOrganizations')
    ->json_is([
        {
            $organization->%{qw(id name description)},
            role => 'admin',
            admins => [
                { map +($_ => $admin_user->$_), qw(id name email) },
                { map +($_ => $new_user->$_), qw(id name email) },
            ],
        },
    ]);

$t->delete_ok('/workspace/'.$grandchild_ws->id.'/organization/'.$organization->{id})
    ->status_is(204)
    ->email_cmp_deeply([
        {
            To => '"'.$admin_user->name.'" <'.$admin_user->email.'>, "'.$new_user->name.'" <'.$new_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch workspaces have been updated',
            body => re(qr/^Your "my first organization" organization has been removed from the\R"grandchild ws" workspace at Joyent Conch\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'We removed an organization from your workspace',
            body => re(qr/^${\$super_user->name} \(${\$super_user->email}\) removed the "my first organization"\Rorganization from the "grandchild ws" workspace at Joyent Conch\./m),
        },
    ]);

$t->get_ok('/workspace/'.$grandchild_ws->id.'/organization')
    ->status_is(200)
    ->json_schema_is('WorkspaceOrganizations')
    ->json_is([
        {
            $organization->%{qw(id name description)},
            role => 'rw',
            role_via_workspace_id => $sub_ws->id,
            admins => [
                { map +($_ => $admin_user->$_), qw(id name email) },
                { map +($_ => $new_user->$_), qw(id name email) },
            ],
        },
    ]);

$t->get_ok('/organization')
    ->status_is(200)
    ->json_schema_is('Organizations')
    ->json_is([ $organization, $organization2 ]);

$t->delete_ok('/organization/my first organization/user/foo@bar.com')
    ->status_is(404);

$t->get_ok('/organization/our second organization/user')
    ->status_is(200)
    ->json_schema_is('OrganizationUsers')
    ->json_is([
        { (map +($_ => $admin_user->$_), qw(id name email)), role => 'admin' },
    ]);

$t->delete_ok('/organization/foo')
    ->status_is(404);

$t->delete_ok('/organization/our second organization')
    ->status_is(204)
    ->log_debug_is('Deactivated organization our second organization, removing 1 user memberships and removing from 0 workspaces and 0 builds');

$t->get_ok('/organization')
    ->status_is(200)
    ->json_schema_is('Organizations')
    ->json_is([ $organization ]);

$t->delete_ok('/organization/my first organization')
    ->status_is(204)
    ->log_debug_is('Deactivated organization my first organization, removing 2 user memberships and removing from 2 workspaces and 0 builds');

$t->get_ok('/organization')
    ->status_is(200)
    ->json_schema_is('Organizations')
    ->json_is([]);

done_testing;
