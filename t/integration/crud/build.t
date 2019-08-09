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
    ->location_like(qr!^/build/${\Conch::UUID::UUID_FORMAT}!)
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
    ->location_like(qr!^/build/${\Conch::UUID::UUID_FORMAT}!)
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


done_testing;
