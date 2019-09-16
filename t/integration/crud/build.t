use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;
use Conch::UUID 'create_uuid_str';

my $t = Test::Conch->new;
my $super_user = $t->load_fixture('super_user');
my $now = Conch::Time->now;

$t->authenticate;

$t->get_ok('/build')
    ->status_is(200)
    ->json_schema_is('Builds')
    ->json_is([]);

$t->post_ok('/build', json => { name => $_, admins => [ { user_id => create_uuid_str() } ] })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/name', message => re(qr/does not match/i) } ])
        foreach '', 'foo/bar', 'foo.bar';

$t->post_ok('/build', json => { name => 'my first build', admins => [ {} ] })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', bag(map +{ path => '/admins/0/'.$_, message => re(qr/missing property/i) }, qw(user_id email)));

$t->post_ok('/build', json => { name => 'my first build' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/admins', message => re(qr/missing property/i) } ] );

$t->post_ok('/build', json => {
        name => 'my first build',
        admins => [ { user_id => create_uuid_str(), email => 'foo@bar.com' } ],
    })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/admins/0', message => re(qr/all of the oneof rules/i) } ] );

$t->post_ok('/build', json => { name => 'my first build', admins => [ { user_id => create_uuid_str() } ] })
    ->status_is(409)
    ->json_cmp_deeply({ error => re(qr/^unrecognized user_id ${\Conch::UUID::UUID_FORMAT}$/) });

$t->post_ok('/build', json => { name => 'my first build', admins => [ { email => 'foo@bar.com' } ] })
    ->status_is(409)
    ->json_is({ error => 'unrecognized email foo@bar.com' });

$t->post_ok('/build', json => {
        name => 'my first build',
        admins => [ { user_id => create_uuid_str() }, { email => 'foo@bar.com' } ],
    })
    ->status_is(409)
    ->json_cmp_deeply({ error => re(qr/^unrecognized user_id ${\Conch::UUID::UUID_FORMAT}, email foo\@bar.com$/) });

my $admin_user = $t->generate_fixtures('user_account');
$t->post_ok('/build', json => { name => 'my first build', admins => [ { user_id => $admin_user->id } ] })
    ->status_is(303)
    ->location_like(qr!^/build/${\Conch::UUID::UUID_FORMAT}$!)
    ->log_info_like(qr/^created build ${\Conch::UUID::UUID_FORMAT} \(my first build\)$/);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('Build')
    ->json_cmp_deeply({
        id => re(Conch::UUID::UUID_FORMAT),
        name => 'my first build',
        description => undef,
        created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        started => undef,
        completed => undef,
        admins => [
            { map +($_ => $admin_user->$_), qw(id name email) },
        ],
        completed_user => undef,
    });
my $build = $t->tx->res->json;

$t->get_ok('/build/my first build')
    ->status_is(200)
    ->json_schema_is('Build')
    ->json_is($build);

$t->get_ok('/build')
    ->status_is(200)
    ->json_schema_is('Builds')
    ->json_is([ $build ]);

$t->post_ok('/build/my first build', json => { description => 'a description' })
    ->status_is(303)
    ->location_is('/build/'.$build->{id});
$build->{description} = 'a description';

$t->get_ok('/build/my first build')
    ->status_is(200)
    ->json_schema_is('Build')
    ->json_is($build);

foreach my $payload (
    { completed => $now },
    { completed => $now, started => $now->plus_days(1) },
    { completed => $now, started => undef },
) {
    $t->post_ok('/build/my first build', json => $payload)
        ->status_is(409)
        ->json_is({ error => 'build cannot be completed before it is started' });
}

$t->post_ok('/build/my first build', json => { started => $now })
    ->status_is(303)
    ->location_is('/build/'.$build->{id})
    ->log_info_is('build '.$build->{id}.' (my first build) started');
$build->{started} = $now->to_string;

$t->get_ok('/build/my first build')
    ->status_is(200)
    ->json_schema_is('Build')
    ->json_is($build);

$t->post_ok('/build/my first build', json => { completed => $now->plus_days(1) })
    ->status_is(303)
    ->location_is('/build/'.$build->{id})
    ->log_info_is("build $build->{id} (my first build) completed; 0 users had role converted from rw to ro");
$build->{completed} = $now->plus_days(1)->to_string;
$build->{completed_user} = { map +($_ => $super_user->$_), qw(id name email) };

$t->get_ok('/build/my first build')
    ->status_is(200)
    ->json_schema_is('Build')
    ->json_is($build);

$t->post_ok('/build/my first build', json => { completed => $now->plus_days(2) })
    ->status_is(409)
    ->json_is({ error => 'build was already completed' });

$t->post_ok('/build/my first build', json => { completed => undef })
    ->status_is(303)
    ->location_is('/build/'.$build->{id})
    ->log_info_is('build '.$build->{id}.' (my first build) moved out of completed state');
$build->{completed} = undef;
$build->{completed_user} = undef;

$t->get_ok('/build/my first build')
    ->status_is(200)
    ->json_schema_is('Build')
    ->json_is($build);

$t->post_ok('/build', json => { name => 'my first build', admins => [ { email => $admin_user->email } ] })
    ->status_is(409)
    ->json_is({ error => 'a build already exists with that name' });

$t->post_ok('/build', json => { name => 'our second build', description => 'funky', admins => [ { email => $admin_user->email } ] })
    ->status_is(303)
    ->location_like(qr!^/build/${\Conch::UUID::UUID_FORMAT}$!)
    ->log_info_like(qr/^created build ${\Conch::UUID::UUID_FORMAT} \(our second build\)$/);

$t->get_ok('/build')
    ->status_is(200)
    ->json_schema_is('Builds')
    ->json_cmp_deeply([
        $build,
        {
            id => re(Conch::UUID::UUID_FORMAT),
            name => 'our second build',
            description => 'funky',
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            started => undef,
            completed => undef,
            admins => [
                { map +($_ => $admin_user->$_), qw(id name email) },
            ],
            completed_user => undef,
        },
    ]);
my $build2 = $t->tx->res->json->[1];

my $new_user = $t->generate_fixtures('user_account');

my $t2 = Test::Conch->new(pg => $t->pg);
$t2->authenticate(email => $new_user->email);

$t2->post_ok('/build', json => { name => 'another build' })
    ->status_is(403)
    ->log_debug_is('User must be system admin');

$t2->get_ok('/build')
    ->status_is(200)
    ->json_schema_is('Builds')
    ->json_is([]);

$t2->get_ok('/build/'.$build->{id})
    ->status_is(403)
    ->log_debug_is('User lacks the required role (ro) for build '.$build->{id});

$t2->get_ok('/build/my first build')
    ->status_is(403)
    ->log_debug_is('User lacks the required role (ro) for build my first build');


$t->get_ok('/build/my first build/user')
    ->status_is(200)
    ->json_schema_is('BuildUsers')
    ->json_is([
        { (map +($_ => $admin_user->$_), qw(id name email)), role => 'admin' },
    ]);

$t->post_ok('/build/'.$build->{id}.'/user', json => { role => 'ro' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', bag(map +{ path => $_, message => re(qr/missing property/i) }, qw(/user_id /email)));

$t->post_ok('/build/my first build/user', json => { email => $new_user->email })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/role', message => re(qr/missing property/i) } ]);

$t->post_ok('/build/my first build/user', json => {
        email => $new_user->email,
        role => 'ro',
    })
    ->status_is(204)
    ->log_info_is('Added user '.$new_user->id.' ('.$new_user->name.') to build my first build with the ro role')
    ->email_cmp_deeply([
        {
            To => '"'.$new_user->name.'" <'.$new_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch access has changed',
            body => re(qr/^You have been added to the "my first build" build at Joyent Conch with the "ro" role\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'We added a user to your build',
            body => re(qr/^${\$super_user->name} \(${\$super_user->email}\) added ${\$new_user->name} \(${\$new_user->email}\) to the\R"my first build" build at Joyent Conch with the "ro" role\./m),
        },
    ]);

$t->get_ok('/build/my first build/user')
    ->status_is(200)
    ->json_schema_is('BuildUsers')
    ->json_is([
        { (map +($_ => $admin_user->$_), qw(id name email)), role => 'admin' },
        { (map +($_ => $new_user->$_), qw(id name email)), role => 'ro' },
    ]);

# non-admin user can only see the build(s) he is a member of
$t2->get_ok('/build')
    ->status_is(200)
    ->json_schema_is('Builds')
    ->json_is([ $build ]);

$t->get_ok('/build/my first build')
    ->status_is(200)
    ->json_schema_is('Build')
    ->json_is($build);

$t2->post_ok('/build/my first build', json => { description => 'I hate this build' })
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for build my first build');

$t2->get_ok('/build/my first build/user')
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for build my first build');

my $new_user2 = $t->generate_fixtures('user_account');
$t2->post_ok('/build/'.$build->{id}.'/user', json => {
        email => $new_user2->email,
        role => 'ro',
    })
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for build '.$build->{id});

$t2->delete_ok('/build/my first build/user/'.$new_user->email)
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for build my first build');


$t->post_ok('/build/'.$build->{id}.'/user', json => {
        email => $new_user->email,
        role => 'rw',
    })
    ->status_is(204)
    ->log_info_is('Updated access for user '.$new_user->id.' ('.$new_user->name.') in build '.$build->{id}.' to the rw role')
    ->email_cmp_deeply([
        {
            To => '"'.$new_user->name.'" <'.$new_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch access has changed',
            body => re(qr/^Your access to the "my first build" build at Joyent Conch has been adjusted to "rw"\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'We modified a user\'s access to your build',
            body => re(qr/^${\$super_user->name} \(${\$super_user->email}\) modified a user's access to your build "my first build" at Joyent Conch\.\R${\$new_user->name} \(${\$new_user->email}\) now has the "rw" role\./m),
        },
    ]);

$t->get_ok('/build/my first build/user')
    ->status_is(200)
    ->json_schema_is('BuildUsers')
    ->json_is([
        { (map +($_ => $admin_user->$_), qw(id name email)), role => 'admin' },
        { (map +($_ => $new_user->$_), qw(id name email)), role => 'rw' },
    ]);

$t2->get_ok('/build/my first build/user')
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for build my first build');

$t2->post_ok('/build/'.$build->{id}.'/user', json => {
        email => $new_user2->email,
        role => 'ro',
    })
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for build '.$build->{id});

$t2->delete_ok('/build/my first build/user/'.$new_user->email)
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for build my first build');

$t->post_ok('/build/my first build', json => { completed => $now->plus_days(2) })
    ->status_is(303)
    ->location_is('/build/'.$build->{id})
    ->log_info_is("build $build->{id} (my first build) completed; 1 users had role converted from rw to ro");
$build->{completed} = $now->plus_days(2)->to_string;
$build->{completed_user} = { map +($_ => $super_user->$_), qw(id name email) };

$t->get_ok('/build/my first build')
    ->status_is(200)
    ->json_schema_is('Build')
    ->json_is($build);

$t->get_ok('/build/my first build/user')
    ->status_is(200)
    ->json_schema_is('BuildUsers')
    ->json_is([
        { (map +($_ => $admin_user->$_), qw(id name email)), role => 'admin' },
        { (map +($_ => $new_user->$_), qw(id name email)), role => 'ro' },
    ]);

$t2->get_ok('/build/my first build/user')
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for build my first build');

my $t_build_admin = Test::Conch->new(pg => $t->pg);
$t_build_admin->authenticate(email => $admin_user->email);

$t_build_admin->get_ok('/build/my first build/user')
    ->status_is(200)
    ->json_schema_is('BuildUsers')
    ->json_is([
        { (map +($_ => $admin_user->$_), qw(id name email)), role => 'admin' },
        { (map +($_ => $new_user->$_), qw(id name email)), role => 'ro' },
    ]);

$t_build_admin->post_ok('/build/'.$build->{id}.'/user', json => {
        email => $new_user2->email,
        role => 'ro',
    })
    ->status_is(204)
    ->log_info_is('Added user '.$new_user2->id.' ('.$new_user2->name.') to build '.$build->{id}.' with the ro role')
    ->email_cmp_deeply([
        {
            To => '"'.$new_user2->name.'" <'.$new_user2->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch access has changed',
            body => re(qr/^You have been added to the "my first build" build at Joyent Conch with the "ro" role\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'We added a user to your build',
            body => re(qr/^${\$admin_user->name} \(${\$admin_user->email}\) added ${\$new_user2->name} \(${\$new_user2->email}\) to the\R"my first build" build at Joyent Conch with the "ro" role\./m),
        },
    ]);

$t_build_admin->get_ok('/build/my first build/user')
    ->status_is(200)
    ->json_schema_is('BuildUsers')
    ->json_is([
        { (map +($_ => $admin_user->$_), qw(id name email)), role => 'admin' },
        { (map +($_ => $new_user->$_), qw(id name email)), role => 'ro' },
        { (map +($_ => $new_user2->$_), qw(id name email)), role => 'ro' },
    ]);

$t_build_admin->delete_ok('/build/my first build/user/'.$new_user2->email)
    ->status_is(204)
    ->log_info_is('removing user '.$new_user2->id.' ('.$new_user2->name.') from build my first build')
    ->email_cmp_deeply([
        {
            To => '"'.$new_user2->name.'" <'.$new_user2->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch builds have been updated',
            body => re(qr/^You have been removed from the "my first build" build at Joyent Conch\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'We removed a user from your build',
            body => re(qr/^${\$admin_user->name} \(${\$admin_user->email}\) removed ${\$new_user2->name} \(${\$new_user2->email}\) from the\R"my first build" build at Joyent Conch\./m),
        },
    ]);

$t_build_admin->get_ok('/build/my first build/user')
    ->status_is(200)
    ->json_schema_is('BuildUsers')
    ->json_is([
        { (map +($_ => $admin_user->$_), qw(id name email)), role => 'admin' },
        { (map +($_ => $new_user->$_), qw(id name email)), role => 'ro' },
    ]);

$admin_user->discard_changes;
$t->delete_ok('/user/'.$admin_user->id)
    ->status_is(409)
    ->json_is({
        error => 'user is the only admin of the "my first build" build ('.$build->{id}.')',
        user => { map +($_ => $admin_user->$_), qw(id email name created deactivated) },
    });

$t->delete_ok('/build/my first build/user/foo@bar.com')
    ->status_is(404);

$t->get_ok('/build/our second build/user')
    ->status_is(200)
    ->json_schema_is('BuildUsers')
    ->json_is([
        { (map +($_ => $admin_user->$_), qw(id name email)), role => 'admin' },
    ]);


my $org_admin = $t->generate_fixtures('user_account');
$t->post_ok('/organization', json => { name => 'my first organization', admins => [ { user_id => $org_admin->id } ] })
    ->status_is(303)
    ->location_like(qr!^/organization/${\Conch::UUID::UUID_FORMAT}$!)
    ->log_info_like(qr/^created organization ${\Conch::UUID::UUID_FORMAT} \(my first organization\)$/);
my $organization = $t->app->db_organizations->find($t->tx->res->headers->location =~ s!^/organization/(${\Conch::UUID::UUID_FORMAT})$!$1!r);

my $org_member = $t->generate_fixtures('user_account');
$t->post_ok('/organization/my first organization/user?send_mail=0', json => {
        email => $org_member->email,
        role => 'ro',
    })
    ->status_is(204)
    ->email_not_sent;

$t->get_ok('/build/'.$build->{id}.'/organization')
    ->status_is(200)
    ->json_schema_is('BuildOrganizations')
    ->json_is([]);

$t->post_ok('/build/'.$build->{id}.'/organization', json => { role => 'ro' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/organization_id', message => re(qr/missing property/i) } ]);

$t->post_ok('/build/'.$build->{id}.'/organization', json => { organization_id => $organization->id })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/role', message => re(qr/missing property/i) } ]);

my $t3 = Test::Conch->new(pg => $t->pg);
$t3->authenticate(email => $new_user2->email);

$t3->get_ok('/build/'.$build->{id}.'/organization')
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for build '.$build->{id});

$t3->post_ok('/build/'.$build->{id}.'/organization', json => {
        organization_id => $organization->id,
        role => 'ro',
    })
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for build '.$build->{id});


$t->post_ok('/build/'.$build->{id}.'/organization', json => {
        organization_id => $organization->id,
        role => 'ro',
    })
    ->status_is(204)
    ->email_cmp_deeply([
        {
            To => '"'.$org_admin->name.'" <'.$org_admin->email.'>, "'.$org_member->name.'" <'.$org_member->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch access has changed',
            body => re(qr/^Your "my first organization" organization has been added to the\R"my first build" build at Joyent Conch with the "ro" role\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'We added an organization to your build',
            body => re(qr/^${\$super_user->name} \(${\$super_user->email}\) added the "my first organization" organization to the\R"my first build" build at Joyent Conch with the "ro" role\./m),
        },
    ]);

$t->get_ok('/build/'.$build->{id}.'/organization')
    ->status_is(200)
    ->json_schema_is('BuildOrganizations')
    ->json_is([
        {
            (map +($_ => $organization->$_), qw(id name description)),
            role => 'ro',
            admins => [
                { map +($_ => $org_admin->$_), qw(id name email) },
            ],
        },
    ]);

$t->post_ok('/build/'.$build->{id}.'/organization', json => {
        organization_id => $organization->id,
        role => 'rw',
    })
    ->status_is(204)
    ->email_cmp_deeply([
        {
            To => '"'.$org_admin->name.'" <'.$org_admin->email.'>, "'.$org_member->name.'" <'.$org_member->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch access has changed',
            body => re(qr/^Your access to the "my first build" build at Joyent Conch\Rvia the "my first organization" organization has been adjusted to the "rw" role\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'We modified an organization\'s access to your build',
            body => re(qr/^${\$super_user->name} \(${\$super_user->email}\) modified the "my first organization" organization's\Raccess to the "my first build" build at Joyent Conch to the "rw" role\./m),
        },
    ]);

$t->get_ok('/build/'.$build->{id}.'/organization')
    ->status_is(200)
    ->json_schema_is('BuildOrganizations')
    ->json_is([
        {
            (map +($_ => $organization->$_), qw(id name description)),
            role => 'rw',
            admins => [
                { map +($_ => $org_admin->$_), qw(id name email) },
            ],
        },
    ]);

$t->post_ok('/build/'.$build->{id}.'/organization', json => {
        organization_id => $organization->id,
        role => 'rw',
    })
    ->status_is(204)
    ->log_debug_is('organization "my first organization" already has rw access to build '.$build->{id}.': nothing to do')
    ->email_not_sent;

$t->post_ok('/build/'.$build->{id}.'/organization', json => {
        organization_id => $organization->id,
        role => 'ro',
    })
    ->status_is(409)
    ->json_is({ error => 'organization "my first organization" already has rw access to build '.$build->{id}.': cannot downgrade role to ro' })
    ->email_not_sent;

$t3->delete_ok('/build/'.$build->{id}.'/organization/my first organization')
    ->status_is(403)
    ->log_debug_is('User lacks the required role (admin) for build '.$build->{id});

$t->delete_ok('/build/'.$build->{id}.'/organization/'.$organization->id)
    ->status_is(204)
    ->email_cmp_deeply([
        {
            To => '"'.$org_admin->name.'" <'.$org_admin->email.'>, "'.$org_member->name.'" <'.$org_member->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch builds have been updated',
            body => re(qr/^Your "my first organization" organization has been removed from the\R"my first build" build at Joyent Conch\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'We removed an organization from your build',
            body => re(qr/^${\$super_user->name} \(${\$super_user->email}\) removed the "my first organization"\Rorganization from the "my first build" build at Joyent Conch\./m),
        },
    ]);

$t->get_ok('/build/'.$build->{id}.'/organization')
    ->status_is(200)
    ->json_schema_is('BuildOrganizations')
    ->json_is([]);


done_testing;
