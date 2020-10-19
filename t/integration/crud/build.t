use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;
use Conch::UUID 'create_uuid_str';
use List::Util 'first';

my $JOYENT = 'Joyent Conch (https://127.0.0.1)';

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
    ->json_cmp_deeply('/details', [
            { path => '/admins', message => re(qr/missing property/i) },
            { path => '/build_id', message => re(qr/missing property/i) },
        ] );

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
$t->post_ok('/build', json => {
      name => 'my first build',
      admins => [ { user_id => $admin_user->id } ],
      links => ['https://foo.com/1', 'https://bar.com/2'],
    })
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
        links => ['https://foo.com/1', 'https://bar.com/2'],
    })
    ->log_debug_is('User has system admin access to build '.$t->tx->res->json->{id});
my $build = $t->tx->res->json;

$t->get_ok('/build/my first build')
    ->status_is(200)
    ->json_schema_is('Build')
    ->json_is($build)
    ->log_debug_is('User has system admin access to build my first build');

$t->get_ok('/build')
    ->status_is(200)
    ->json_schema_is('Builds')
    ->json_is([ $build ]);

$t->post_ok('/build/my first build', json => { description => 'a description', links => ['https://baz.com/3'] })
    ->status_is(303)
    ->location_is('/build/'.$build->{id});
$build->{description} = 'a description';
$build->{links} = ['https://baz.com/3'];

$t->get_ok('/build/my first build')
    ->status_is(200)
    ->json_schema_is('Build')
    ->json_is($build);

foreach my $payload (
    { completed => $now },
    { completed => $now->minus_days(1), started => $now },
    { completed => $now, started => undef },
) {
    $t->post_ok('/build/my first build', json => $payload)
        ->status_is(409)
        ->json_is({ error => 'build cannot be completed before it is started' });
}

$t->post_ok('/build/my first build', json => { started => $now->minus_days(7) })
    ->status_is(303)
    ->location_is('/build/'.$build->{id})
    ->log_info_is('build '.$build->{id}.' (my first build) started');
$build->{started} = $now->minus_days(7)->to_string;

$t->get_ok('/build/my first build')
    ->status_is(200)
    ->json_schema_is('Build')
    ->json_is($build);

$t->post_ok('/build/my first build', json => { completed => $now->plus_days(1) })
    ->status_is(409)
    ->json_is({ error => 'build cannot be completed in the future' });

$t->post_ok('/build/my first build', json => { completed => $now->minus_days(1) })
    ->status_is(303)
    ->location_is('/build/'.$build->{id})
    ->log_info_is("build $build->{id} (my first build) completed; 0 users had role converted from rw to ro");
$build->{completed} = $now->minus_days(1)->to_string;
$build->{completed_user} = { map +($_ => $super_user->$_), qw(id name email) };

$t->get_ok('/build/my first build')
    ->status_is(200)
    ->json_schema_is('Build')
    ->json_is($build);

$t->post_ok('/build/my first build', json => { completed => $now })
    ->status_is(409)
    ->json_is({ error => 'build was already completed' });

$t->post_ok('/build/my first build', json => { completed => undef })
    ->status_is(303)
    ->location_is('/build/'.$build->{id})
    ->log_info_is('build '.$build->{id}.' (my first build) moved out of completed state');
$build->{completed} = undef;
$build->{completed_user} = undef;

$t->post_ok('/build/my first build/links', json => { links => ['https://alpha.com/1'] })
    ->status_is(303)
    ->location_is('/build/'.$build->{id});
$build->{links} = ['https://alpha.com/1', 'https://baz.com/3'];

$t->get_ok('/build/my first build')
    ->status_is(200)
    ->json_schema_is('Build')
    ->json_is($build);

$t->delete_ok('/build/my first build/links', json => { links => [ 'https://does-not-exist.com' ] })
    ->status_is(204);

$t->delete_ok('/build/my first build/links', json => { links => ['https://alpha.com/1'] })
    ->status_is(204);
$build->{links} = ['https://baz.com/3'];

$t->get_ok('/build/my first build')
    ->status_is(200)
    ->json_schema_is('Build')
    ->json_is($build);

$t->delete_ok('/build/my first build/links')
    ->status_is(204);
$build->{links} = [];

$t->get_ok('/build/my first build')
    ->status_is(200)
    ->json_schema_is('Build')
    ->json_is($build);


$t->post_ok('/build', json => { name => 'my first build', admins => [ { email => $admin_user->email } ] })
    ->status_is(409)
    ->json_is({ error => 'a build already exists with that name' });

$t->post_ok('/build', json => {
        name => 'our second build',
        description => 'funky',
        started => '2019-01-01T00:00:00Z',
        build_id => create_uuid_str,
    })
    ->status_is(409)
    ->json_cmp_deeply({ error => re(qr/^unrecognized build_id ${\Conch::UUID::UUID_FORMAT}$/) });

$t->post_ok('/build', json => {
        name => 'our second build',
        description => 'funky',
        started => '2019-01-01T00:00:00Z',
        build_id => $build->{id},
    })
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
            started => '2019-01-01T00:00:00.000Z',
            completed => undef,
            admins => [
                { map +($_ => $admin_user->$_), qw(id name email) },
            ],
            completed_user => undef,
            links => [],
        },
    ]);
my $build2 = $t->tx->res->json->[1];

$t->post_ok('/build/our second build', json => { name => 'my first build' })
    ->status_is(409)
    ->json_is({ error => 'duplicate build found' });

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
            From => 'noreply@joyent.com',
            Subject => 'Your Conch access has changed',
            body => re(qr/^You have been added to the "my first build" build at \Q$JOYENT\E with the "ro" role\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>',
            From => 'noreply@joyent.com',
            Subject => 'We added a user to your build',
            body => re(qr/^${\$super_user->name} \(${\$super_user->email}\) added ${\$new_user->name} \(${\$new_user->email}\) to the\R"my first build" build at \Q$JOYENT\E with the "ro" role\./m),
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

$t2->get_ok('/build/my first build')
    ->status_is(200)
    ->json_schema_is('Build')
    ->json_is($build)
    ->log_debug_is('User has ro access to build my first build via role entry');

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
            From => 'noreply@joyent.com',
            Subject => 'Your Conch access has changed',
            body => re(qr/^Your access to the "my first build" build at \Q$JOYENT\E has been adjusted to "rw"\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>',
            From => 'noreply@joyent.com',
            Subject => 'We modified a user\'s access to your build',
            body => re(qr/^${\$super_user->name} \(${\$super_user->email}\) modified a user's access to your build\R"my first build" at \Q$JOYENT\E\.\R${\$new_user->name} \(${\$new_user->email}\) now has the "rw" role\./m),
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

$t->post_ok('/build/my first build', json => { completed => $now->minus_hours(2) })
    ->status_is(303)
    ->location_is('/build/'.$build->{id})
    ->log_info_is("build $build->{id} (my first build) completed; 1 users had role converted from rw to ro");
$build->{completed} = $now->minus_hours(2)->to_string;
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
    ->log_debug_is('User has admin access to build '.$build->{id}.' via role entry')
    ->log_info_is('Added user '.$new_user2->id.' ('.$new_user2->name.') to build '.$build->{id}.' with the ro role')
    ->email_cmp_deeply([
        {
            To => '"'.$new_user2->name.'" <'.$new_user2->email.'>',
            From => 'noreply@joyent.com',
            Subject => 'Your Conch access has changed',
            body => re(qr/^You have been added to the "my first build" build at \Q$JOYENT\E with the "ro" role\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>',
            From => 'noreply@joyent.com',
            Subject => 'We added a user to your build',
            body => re(qr/^${\$admin_user->name} \(${\$admin_user->email}\) added ${\$new_user2->name} \(${\$new_user2->email}\) to the\R"my first build" build at \Q$JOYENT\E with the "ro" role\./m),
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
            From => 'noreply@joyent.com',
            Subject => 'Your Conch builds have been updated',
            body => re(qr/^You have been removed from the "my first build" build at \Q$JOYENT\E\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>',
            From => 'noreply@joyent.com',
            Subject => 'We removed a user from your build',
            body => re(qr/^${\$admin_user->name} \(${\$admin_user->email}\) removed ${\$new_user2->name} \(${\$new_user2->email}\) from the\R"my first build" build at \Q$JOYENT\E\./m),
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

# wtf is this?
$t->delete_ok('/build/my first build/user/foo@bar.com')
    ->status_is(404)
    ->log_debug_is('Could not find user foo@bar.com');

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
            From => 'noreply@joyent.com',
            Subject => 'Your Conch access has changed',
            body => re(qr/^Your "my first organization" organization has been added to the\R"my first build" build at \Q$JOYENT\E with the "ro" role\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>',
            From => 'noreply@joyent.com',
            Subject => 'We added an organization to your build',
            body => re(qr/^${\$super_user->name} \(${\$super_user->email}\) added the "my first organization" organization to the\R"my first build" build at \Q$JOYENT\E with the "ro" role\./m),
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

$t->get_ok('/organization/my first organization')
    ->status_is(200)
    ->json_schema_is('Organization')
    ->json_cmp_deeply({
        (map +($_ => $organization->$_), qw(id name description)),
        created => $organization->created.'',
        users => [
            { (map +($_ => $org_admin->$_), qw(id name email)), role => 'admin' },
            { (map +($_ => $org_member->$_), qw(id name email)), role => 'ro' },
        ],
        builds => [ +{ $build->%{qw(id name description)}, role => 'ro' } ],
    });

$t->post_ok('/build/'.$build->{id}.'/organization', json => {
        organization_id => $organization->id,
        role => 'rw',
    })
    ->status_is(204)
    ->email_cmp_deeply([
        {
            To => '"'.$org_admin->name.'" <'.$org_admin->email.'>, "'.$org_member->name.'" <'.$org_member->email.'>',
            From => 'noreply@joyent.com',
            Subject => 'Your Conch access has changed',
            body => re(qr/^Your access to the "my first build" build at \Q$JOYENT\E\Rvia the "my first organization" organization has been adjusted to the "rw" role\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>',
            From => 'noreply@joyent.com',
            Subject => 'We modified an organization\'s access to your build',
            body => re(qr/^${\$super_user->name} \(${\$super_user->email}\) modified the "my first organization" organization's\Raccess to the "my first build" build at \Q$JOYENT\E to the "rw" role\./m),
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

$t->app->db_organization_build_roles->create({
    organization_id => $organization->id,
    build_id => $build2->{id},
    role => 'ro',
});

$t->delete_ok('/build/'.$build->{id}.'/organization/'.$organization->id)
    ->status_is(204)
    ->email_cmp_deeply([
        {
            To => '"'.$org_admin->name.'" <'.$org_admin->email.'>, "'.$org_member->name.'" <'.$org_member->email.'>',
            From => 'noreply@joyent.com',
            Subject => 'Your Conch builds have been updated',
            body => re(qr/^Your "my first organization" organization has been removed from the\R"my first build" build at \Q$JOYENT\E\./m),
        },
        {
            To => '"'.$super_user->name.'" <'.$super_user->email.'>, "'.$admin_user->name.'" <'.$admin_user->email.'>',
            From => 'noreply@joyent.com',
            Subject => 'We removed an organization from your build',
            body => re(qr/^${\$super_user->name} \(${\$super_user->email}\) removed the "my first organization"\Rorganization from the "my first build" build at \Q$JOYENT\E\./m),
        },
    ]);

$t->get_ok('/build/'.$build->{id}.'/organization')
    ->status_is(200)
    ->json_schema_is('BuildOrganizations')
    ->json_is([]);

$t->get_ok('/build/'.$build2->{id}.'/organization')
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

$t->get_ok('/build/our second build/device')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is([]);

$t->get_ok('/build/our second build/rack')
    ->status_is(200)
    ->json_schema_is('Racks')
    ->json_is([]);

$t->post_ok('/build/our second build/device', json => [ { serial_number => 'FOO' } ])
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/0/sku', message => re(qr/missing property/i) } ]);

$t->post_ok('/build/our second build/device', json => [ { sku => 'ugh' } ])
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [
            { path => '/0/id', message => re(qr/missing property/i) },
            { path => '/0/serial_number', message => re(qr/missing property/i) },
        ]);

$t->app->db_builds->search({ id => $build2->{id} })->update({ completed => \'now()', completed_user_id => $super_user->id });

$t->post_ok('/build/our second build/device', json => [ { serial_number => 'FOO', sku => 'nope' } ])
    ->status_is(409)
    ->json_is({ error => 'cannot add devices to a completed build' });

$t->app->db_builds->search({ id => $build2->{id} })->update({ completed => undef, completed_user_id => undef });

$t->post_ok('/build/our second build/device', json => [ { serial_number => 'FOO', sku => 'nope' } ])
    ->status_is(404)
    ->json_is({ error => 'no hardware_product corresponding to sku nope' })
    ->log_warn_is('no hardware_product corresponding to sku nope');

my $hardware_product = first { $_->isa('Conch::DB::Result::HardwareProduct') } $t->generate_fixtures('hardware_product');

$t->post_ok('/build/our second build/device', json => [ { id => create_uuid_str(), sku => $hardware_product->sku } ])
    ->status_is(404)
    ->json_cmp_deeply({ error => re(qr/^no device corresponding to device id ${\Conch::UUID::UUID_FORMAT}$/) })
    ->log_warn_like(qr/^no device corresponding to device id ${\Conch::UUID::UUID_FORMAT}$/);

$t2->post_ok('/build/our second build/device', json => [ { serial_number => 'FOO', sku => $hardware_product->sku } ])
    ->status_is(403)
    ->log_debug_is('User lacks the required role (rw) for build our second build');

my $other_device = $t->app->db_devices->create({
    serial_number => 'another_device',
    hardware_product_id => $hardware_product->id,
    health => 'unknown',
});

$t_build_admin->post_ok('/build/our second build/device', json => [ { serial_number => 'another_device', sku => $hardware_product->sku } ])
    ->status_is(403)
    ->log_debug_is('User lacks the required role (rw) for one or more devices');

$t->post_ok('/build/our second build/device', json => [ { serial_number => 'FOO', sku => $hardware_product->sku } ])
    ->status_is(204)
    ->log_debug_is('created new device FOO in build our second build');

$t->get_ok('/build/our second build/device')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_cmp_deeply([
        superhashof({
            serial_number => 'FOO',
            hardware_product_id => $hardware_product->id,
            sku => $hardware_product->sku,
            health => 'unknown',
            asset_tag => undef,
            links => [],
            (map +('build_'.$_ => $build2->{$_}), qw(id name)),
            (map +($_ => undef), qw(rack_id rack_name rack_unit_start)),
        }),
    ]);
my $devices = $t->tx->res->json;

$t->get_ok('/build/our second build/device?health=foo')
    ->status_is(400)
    ->json_schema_is('QueryParamsValidationError')
    ->json_cmp_deeply('/details', [
        { path => '/health', message => re(qr/Not in enum list/) },
        { path => '/health', message => re(qr/Expected array - got string/) },
    ]);

$t->get_ok('/build/our second build/device?health=fail')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is([]);

$t->get_ok('/build/our second build/device?health=unknown')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is($devices);

$t->get_ok('/build/our second build/device?ids_only=1&serials_only=1')
    ->status_is(400)
    ->json_schema_is('QueryParamsValidationError')
    ->json_cmp_deeply('/details', [ { path => '/', message => re(qr{should not match}i) } ]);

$t->get_ok('/build/our second build/device?ids_only=1')
    ->status_is(200)
    ->json_schema_is('DeviceIds')
    ->json_is([ $devices->[0]{id} ]);

$t->get_ok('/build/our second build/device?serials_only=1')
    ->status_is(200)
    ->json_schema_is('DeviceSerials')
    ->json_is([ $devices->[0]{serial_number} ]);

$t->get_ok('/build/our second build/device?active_minutes=5')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is([]);

$t->app->db_devices->search({ id => $devices->[0]{id} })->update({ last_seen => $now });
$devices->[0]{last_seen} = $now->to_string;

$t->get_ok('/build/our second build/device?active_minutes=5')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is($devices);

$t->get_ok('/build?with_device_health&with_device_phases&with_rack_phases')
    ->status_is(200)
    ->json_schema_is('Builds')
    ->json_is([
        {
            $build->%*,
            device_health => {
                error => 0,
                fail => 0,
                unknown => 0,
                pass => 0,
            },
            device_phases => {
                integration => 0,
                installation => 0,
                production => 0,
                diagnostics => 0,
                decommissioned => 0,
            },
            rack_phases => {
                integration => 0,
                installation => 0,
                production => 0,
                diagnostics => 0,
                decommissioned => 0,
            },
        },
        {
            $build2->%*,
            device_health => {
                error => 0,
                fail => 0,
                unknown => 1,
                pass => 0,
            },
            device_phases => {
                integration => 1,
                installation => 0,
                production => 0,
                diagnostics => 0,
                decommissioned => 0,
            },
            rack_phases => {
                integration => 0,
                installation => 0,
                production => 0,
                diagnostics => 0,
                decommissioned => 0,
            },
        },
    ]);

$t->get_ok('/build/our second build?with_device_health&with_device_phases&with_rack_phases')
    ->status_is(200)
    ->json_schema_is('Build')
    ->json_is({
        $build2->%*,
        device_health => {
            error => 0,
            fail => 0,
            unknown => 1,
            pass => 0,
        },
        device_phases => {
            integration => 1,
            installation => 0,
            production => 0,
            diagnostics => 0,
            decommissioned => 0,
        },
        rack_phases => {
            integration => 0,
            installation => 0,
            production => 0,
            diagnostics => 0,
            decommissioned => 0,
        },
    });

$t->post_ok('/build/our second build/device', json => [ {
        serial_number => 'FOO',
        sku => $hardware_product->sku,
    } ])
    ->status_is(204);

$t->get_ok('/build/our second build/device')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is($devices);    # identical payload, including update timestamp

$t->post_ok('/build/our second build/device', json => [ { id => $devices->[0]{id}, sku => 'nope' } ])
    ->status_is(404)
    ->log_warn_is('no hardware_product corresponding to sku nope');

$t->post_ok('/build/our second build/device', json => [ { serial_number => 'FOO', sku => 'nope' } ])
    ->status_is(404)
    ->log_warn_is('no hardware_product corresponding to sku nope');

$t->post_ok('/build/our second build/device', json => [ {
            id => $devices->[0]{id},
            serial_number => $other_device->serial_number,
            sku => $hardware_product->sku,
        }, ])
    ->status_is(400)
    ->json_cmp_deeply({ error => re(qr/duplicate key value violates unique constraint "device_serial_number_key"/) });

$t->post_ok('/build/our second build/device', json => [ {
            serial_number => 'FOO',
            sku => $hardware_product->sku,
            asset_tag => 'fooey',
            links => [ 'https://foo.bar.com' ],
        } ])
    ->log_debug_is('updated device FOO ('.$devices->[0]{id}.') in build our second build')
    ->status_is(204);

$t->get_ok('/build/our second build/device')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_cmp_deeply([
        {
            $devices->[0]->%*,
            asset_tag => 'fooey',
            links => [ 'https://foo.bar.com' ],
            (map +('build_'.$_ => $build2->{$_}), qw(id name)),
            updated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        },
    ]);
my $new_device = $t->tx->res->json->[0];

$t->get_ok('/build/my first build/device')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is([]);

my $device1 = first { $_->isa('Conch::DB::Result::Device') } $t->generate_fixtures('device');
my $rack_layout1 = first { $_->isa('Conch::DB::Result::RackLayout') } $t->generate_fixtures('rack_layouts');
my $rack1 = $rack_layout1->rack;
my $room1 = $rack1->datacenter_room;

$t2->post_ok('/build/my first build/rack/'.$rack1->id)
    ->status_is(403)
    ->log_debug_is('User lacks the required role (rw) for build my first build');

$t_build_admin->post_ok('/build/my first build/rack/'.$rack1->id)
    ->status_is(403)
    ->log_debug_is('User lacks the required role (rw) for rack '.$rack1->id);

$t->post_ok('/build/my first build/rack/'.$rack1->id)
    ->status_is(409)
    ->json_is({ error => 'cannot add a rack to a completed build' });

$t->app->db_builds->search({ id => $build->{id} })->update({ completed => undef, completed_user_id => undef });

$t->post_ok('/build/my first build/rack/'.$rack1->id)
    ->status_is(204)
    ->log_debug_is('adding rack '.$rack1->id.' to build my first build');

$t->post_ok($_)
    ->status_is(204)
    foreach
        '/build/'.$build->{id}.'/rack/'.$rack1->id,
        '/build/'.$build->{id}.'/rack/'.$room1->vendor_name.':'.$rack1->name,
        '/build/my first build/rack/'.$rack1->id,
        '/build/my first build/rack/'.$room1->vendor_name.':'.$rack1->name;

$t->get_ok('/build/my first build/rack')
    ->status_is(200)
    ->json_schema_is('Racks')
    ->json_cmp_deeply([
        superhashof({ id => $rack1->id }),
    ]);

$t->get_ok('/build/my first build/device')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is([]);

$device1->create_related('device_location', { rack_id => $rack1->id, rack_unit_start => $rack_layout1->rack_unit_start });

$t->get_ok('/build/my first build/device')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_cmp_deeply([ superhashof({
        (map +($_ => $device1->$_), qw(id serial_number)),
        (map +('build_'.$_ => undef), qw(id name)), # in the build via the rack, not directly (FIXME)
        rack_id => $rack1->id,
        rack_name => $rack1->datacenter_room->vendor_name.':'.$rack1->name,
        rack_unit_start => $device1->device_location->rack_unit_start,
    }) ]);


# create a new device, located in a different rack in a different build
my $device2 = first { $_->isa('Conch::DB::Result::Device') } $t->generate_fixtures('device');
$device2->update({ build_id => $build->{id} });
my $rack_layout2 = first { $_->isa('Conch::DB::Result::RackLayout') } $t->generate_fixtures('rack_layouts');
my $rack2 = $rack_layout2->rack;
$rack2->update({ build_id => $build2->{id} });
$device2->create_related('device_location', { rack_id => $rack2->id, rack_unit_start => $rack_layout2->rack_unit_start });

$t->get_ok('/build/our second build/device')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_cmp_deeply([
        $new_device,
        # device2 is in rack2, but in build1, so it should not be listed here.
    ]);

$device2->update({ build_id => undef });

$t->get_ok('/build/our second build/device')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_cmp_deeply([
        $new_device,
        # now device2 is in build2 via rack2
        superhashof({
            (map +($_ => $device2->$_), qw(id serial_number)),
            (map +('build_'.$_ => undef), qw(id name)), # in the build via the rack, not directly (FIXME)
            rack_id => $rack2->id,
            rack_name => $rack2->datacenter_room->vendor_name.':'.$rack2->name,
            rack_unit_start => $device2->device_location->rack_unit_start,
        }),
    ]);

$device2->delete_related('device_location');

$t2->post_ok('/build/my first build/device/'.$device2->id)
    ->status_is(403)
    ->log_debug_is('User lacks the required role (rw) for build my first build');

$t_build_admin->post_ok('/build/my first build/device/'.$device2->id)
    ->status_is(403)
    ->log_debug_is('User lacks the required role (rw) for device '.$device2->id);

$t->app->db_builds->search({ id => $build->{id} })->update({ completed => \'now()', completed_user_id => $super_user->id });

$t->post_ok('/build/my first build/device/'.$device2->id)
    ->status_is(409)
    ->json_is({ error => 'cannot add a device to a completed build' });

$t->post_ok('/build/my first build', json => { completed => undef })
    ->status_is(303)
    ->location_is('/build/'.$build->{id})
    ->log_info_is('build '.$build->{id}.' (my first build) moved out of completed state');
$build->{completed} = undef;
$build->{completed_user} = undef;

$t->post_ok('/build/my first build/device/'.$device2->id)
    ->status_is(204)
    ->log_debug_is('adding device '.$device2->id.' ('.$device2->serial_number.') to build my first build');

# build1 contains device2 directly.
# build1 contains rack1, which has device1 in it (which is not in the build)
# build2 contains new_device directly, and rack2.

$t->get_ok('/build/my first build/device')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_cmp_deeply([
        superhashof({
            (map +($_ => $device1->$_), qw(id serial_number)),
            (map +('build_'.$_ => undef), qw(id name)), # in the build via the rack, not directly (FIXME)
            rack_id => $rack1->id,
            rack_name => $rack1->datacenter_room->vendor_name.':'.$rack1->name,
            rack_unit_start => $device1->device_location->rack_unit_start,
        }),
        superhashof({
            (map +($_ => $device2->$_), qw(id serial_number)),
            (map +('build_'.$_ => $build->{$_}), qw(id name)),
            (map +($_ => undef), qw(rack_id rack_name rack_unit_start)),
        }),
    ]);

$t->get_ok('/build/my first build/rack')
    ->status_is(200)
    ->json_schema_is('Racks')
    ->json_cmp_deeply([
        superhashof({ id => $rack1->id }),
    ]);

$t->get_ok('/build/our second build/device')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is([ $new_device ]);

$t->get_ok('/build/our second build/rack')
    ->status_is(200)
    ->json_schema_is('Racks')
    ->json_cmp_deeply([
        superhashof({ id => $rack2->id }),
    ]);

$t->get_ok('/build?with_device_health&with_device_phases&with_rack_phases')
    ->status_is(200)
    ->json_schema_is('Builds')
    ->json_is([
        {
            $build->%*,
            device_health => {
                error => 0,
                fail => 0,
                unknown => 1,
                pass => 0,
            },
            device_phases => {
                integration => 1,
                installation => 0,
                production => 0,
                diagnostics => 0,
                decommissioned => 0,
            },
            rack_phases => {
                integration => 1,
                installation => 0,
                production => 0,
                diagnostics => 0,
                decommissioned => 0,
            },
        },
        {
            $build2->%*,
            device_health => {
                error => 0,
                fail => 0,
                unknown => 1,
                pass => 0,
            },
            device_phases => {
                integration => 1,
                installation => 0,
                production => 0,
                diagnostics => 0,
                decommissioned => 0,
            },
            rack_phases => {
                integration => 1,
                installation => 0,
                production => 0,
                diagnostics => 0,
                decommissioned => 0,
            },
        },
    ]);


$device1->discard_changes;
$device2->discard_changes;

# health = (unknown, pass)
# phase = (integration, production)
foreach my $device1_health (0, 1) {
  foreach my $device2_health (0, 1) {
    foreach my $device1_phase (0, 1) {
      foreach my $device2_phase (0, 1) {
        $device1->update({
            health => ($device1_health ? 'pass' : 'unknown'),
            phase => ($device1_phase ? 'production' : 'integration'),
          });
        $device2->update({
            health => ($device2_health ? 'pass' : 'unknown'),
            phase => ($device2_phase ? 'production' : 'integration'),
          });

        note '';
        note 'device1 health = '.$device1->health;
        note 'device1 phase = '.$device1->phase;
        note 'device2 health = '.$device2->health;
        note 'device2 phase = '.$device2->phase;

        $t->post_ok('/build/my first build', json => { completed => $now->minus_days(1) });

        if (($device1_health or $device1_phase) and ($device2_health or $device2_phase)) {
          $t->status_is(303)
          ->location_is('/build/'.$build->{id})
          ->log_info_is("build $build->{id} (my first build) completed; 0 users had role converted from rw to ro");
        }
        else {
          $t->status_is(409)
            ->json_is({ error => 'build cannot be completed when it has unhealthy devices' });
        }

        $t->app->db_builds->search({ id => $build->{id} })
          ->update({ completed => undef, completed_user_id => undef })
            if not ($device1_health and $device1_phase and $device2_health and $device2_phase);
      }
    }
  }
}

$device1->update({ health => 'pass', phase => 'production' });
$device2->update({ health => 'pass', phase => 'integration' });

$t->app->db_builds->search({ id => $build->{id} })->update({ completed => undef, completed_user_id => undef });
$build->{completed} = undef;
$build->{completed_user} = undef;

$t->get_ok('/build/my first build/device')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_cmp_deeply([
        # device1 phase >= production, so its location is no longer canonical
        superhashof({
            (map +($_ => $device2->$_), qw(id serial_number)),
            (map +('build_'.$_ => $build->{$_}), qw(id name)),
            (map +($_ => undef), qw(rack_id rack_name rack_unit_start)),
        }),
    ]);

$t->get_ok('/build/my first build/device?phase_earlier_than=')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_cmp_deeply([
        superhashof({
            (map +('build_'.$_ => undef), qw(id name)), # in the build via the rack, not directly (FIXME)
            # rack_id omitted because phase=production
        }),
        superhashof({
            (map +($_ => $device2->$_), qw(id serial_number)),
            (map +('build_'.$_ => $build->{$_}), qw(id name)),
            (map +($_ => undef), qw(rack_id rack_name rack_unit_start)),
        }),
    ]);

$t->get_ok('/build?with_device_health&with_device_phases&with_rack_phases')
    ->status_is(200)
    ->json_schema_is('Builds')
    ->json_is([
        {
            $build->%*,
            device_health => {
                error => 0,
                fail => 0,
                unknown => 0,
                pass => 1,
            },
            device_phases => {
                integration => 1,
                installation => 0,
                production => 0,
                diagnostics => 0,
                decommissioned => 0,
            },
            rack_phases => {
                integration => 1,
                installation => 0,
                production => 0,
                diagnostics => 0,
                decommissioned => 0,
            },
        },
        {
            $build2->%*,
            device_health => {
                error => 0,
                fail => 0,
                unknown => 1,
                pass => 0,
            },
            device_phases => {
                integration => 1,
                installation => 0,
                production => 0,
                diagnostics => 0,
                decommissioned => 0,
            },
            rack_phases => {
                integration => 1,
                installation => 0,
                production => 0,
                diagnostics => 0,
                decommissioned => 0,
            },
        },
    ]);

$device1->update({ phase => 'integration' });

subtest 'Devices with PXE data' => sub {
    $t->app->db_device_neighbors->delete;
    $t->app->db_device_nics->delete;
    $t->app->db_device_nics->create($_) foreach (
        {
            device_id => $device1->id,
            state => 'up',
            iface_name => 'milhouse',
            iface_type => 'human',
            iface_vendor => 'Groening',
            mac => '00:00:00:00:00:aa',
            ipaddr => '0.0.0.1',
        },
        {
            device_id => $device1->id,
            state => 'up',
            iface_name => 'ned',
            iface_type => 'human',
            iface_vendor => 'Groening',
            mac => '00:00:00:00:00:bb',
            ipaddr => '0.0.0.2',
        },
        {
            device_id => $device1->id,
            state => undef,
            iface_name => 'ipmi1',
            iface_type => 'human',
            iface_vendor => 'Groening',
            mac => '00:00:00:00:00:cc',
            ipaddr => '0.0.0.3',
        },
    );

    $t->get_ok('/build/my first build/device/pxe')
        ->status_is(200)
        ->json_schema_is('DevicePXEs')
        ->json_cmp_deeply([
            {
                id => $device1->id,
                phase => 'integration',
                location => {
                    az => $rack1->datacenter_room->az,
                    datacenter_room => $rack1->datacenter_room->alias,
                    rack => $rack1->datacenter_room->vendor_name.':'.$rack1->name,
                    rack_unit_start => $rack_layout1->rack_unit_start,
                    target_hardware_product => superhashof({ alias => $rack_layout1->hardware_product->alias }),
                },
                ipmi => {
                    mac => '00:00:00:00:00:cc',
                    ip => '0.0.0.3',
                },
                pxe => {
                    mac => '00:00:00:00:00:aa',
                },
            },
            {
                id => $device2->id,
                phase => 'integration',
                location => undef,
                ipmi => undef,
                pxe => undef,
            },
        ]);
    my $pxe_data = $t->tx->res->json;

    $device1->update({ phase => 'production' });
    delete $pxe_data->[0]{location};
    $pxe_data->[0]{phase} = 'production';

    $t->get_ok('/build/my first build/device/pxe')
        ->status_is(200)
        ->json_schema_is('DevicePXEs')
        ->json_is([ $pxe_data->[1] ]);

    $t->get_ok('/build/my first build/device/pxe?phase_earlier_than=')
        ->status_is(200)
        ->json_schema_is('DevicePXEs')
        ->json_is($pxe_data);
};

$t->post_ok('/build/our second build/device', json => [ {
            id => $device2->id,
            sku => $hardware_product->sku,
        } ])
    ->status_is(204);

$t->post_ok('/build/our second build/device', json => [ {
            id => $device1->id,
            sku => $hardware_product->sku,
        } ])
    ->status_is(204);

$t->delete_ok('/build/my first build/device/'.$device1->id)
    ->status_is(404)
    ->log_warn_is('device '.$device1->id.' is not in build my first build: cannot remove');

$t->get_ok('/build/my first build/device')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_is([]);

$t->get_ok('/build/our second build/device')
    ->status_is(200)
    ->json_schema_is('Devices')
    ->json_cmp_deeply([
        $new_device,
        superhashof({
            (map +($_ => $device1->$_), qw(id serial_number)),
            (map +('build_'.$_ => $build2->{$_}), qw(id name)),
            # device.phase >= production, so its location is no longer canonical
        }),
        superhashof({
            (map +($_ => $device2->$_), qw(id serial_number)),
            (map +('build_'.$_ => $build2->{$_}), qw(id name)),
            (map +($_ => undef), qw(rack_id rack_name rack_unit_start)),
        }),
    ]);

done_testing;
