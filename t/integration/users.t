use strict;
use warnings;
use warnings FATAL => 'utf8';
use utf8;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More;
use Conch::UUID 'create_uuid_str';
use Path::Tiny;
use Test::Warnings ':all';
use Test::Conch;
use Test::Deep;
use Test::Deep::NumberTolerant;
use Time::HiRes 'time'; # time() now has µs precision
use Test::Memory::Cycle;

my $t = Test::Conch->new;
my $super_user = $t->load_fixture('super_user');
my $ro_user = $t->load_fixture('ro_user');
my $global_ws = $t->load_fixture('global_workspace');
my $child_ws = $global_ws->create_related('workspaces', { name => 'child_ws', user_workspace_roles => [{ role => 'ro', user_id => $ro_user->id }] });
my $organization = $t->load_fixture('ro_user_organization')->organization;

my ($build1, $build2) = map $t->generate_fixtures('build'), 0..1;
$build1->create_related('user_build_roles', { user_id => $ro_user->id, role => 'ro' });
$build1->create_related('organization_build_roles', { organization_id => $organization->id, role => 'rw' });
$build2->create_related('organization_build_roles', { organization_id => $organization->id, role => 'ro' });

$t->post_ok('/login', json => { email => 'a', password => 'b' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/email', message => re(qr/does not match/i) } ]);

$t->post_ok('/login', json => { email => 'foo@bar.com' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/password', message => re(qr/missing property/i) } ]);

$t->post_ok('/login', json => { email => 'foo@bar.com', password => 'b' })
    ->status_is(401)
    ->log_debug_is('user lookup for foo@bar.com failed');

my $now = Conch::Time->now;

$t->authenticate(email => $ro_user->email);

isa_ok($t->tx->res->cookie('conch'), 'Mojo::Cookie::Response');

$ro_user->discard_changes;
ok($ro_user->last_login >= $now, 'user last_login is updated');
ok($ro_user->last_seen >= $now, 'user last_seen is updated');

$now = Conch::Time->now;

$t->get_ok('/me')
    ->status_is(204);

$ro_user->discard_changes;
ok($ro_user->last_login < $now, 'user last_login is not updated with normal auth');
ok($ro_user->last_seen >= $now, 'user last_seen is updated');

my $super_user_data;
my $user_detailed;

my $t_super = Test::Conch->new(pg => $t->pg);
$t_super->authenticate(email => $super_user->email);

subtest 'User' => sub {
    $t->get_ok('/user/me/settings')
        ->status_is(200)
        ->json_schema_is('UserSettings')
        ->json_is({});

    $t->get_ok('/user/me/settings/BAD')
        ->status_is(404);

    $t->post_ok('/user/me/settings/TEST', json => { NOTTEST => 'test' })
        ->status_is(400)
        ->json_is({ error => "Setting key in request payload must match name in the URL ('TEST')" });

    $t->post_ok('/user/me/settings/TEST', json => { TEST => 'bar', MORETEST => 'quux' })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', [ { path => '/', message => re(qr/too many properties/i) } ]);

    $t->post_ok('/user/me/settings/FOO/BAR', json => { 'FOO/BAR' => 'TEST' })
        ->status_is(404);

    $t->post_ok('/user/me/settings/TEST', json => { TEST => 'TEST' })
        ->status_is(204);

    $t->get_ok('/user/me/settings/TEST')
        ->status_is(200)
        ->json_schema_is('UserSetting')
        ->json_is({ TEST => 'TEST' });

    $t->get_ok('/user/me/settings')
        ->status_is(200)
        ->json_schema_is('UserSettings')
        ->json_is({ TEST => 'TEST' });

    $t->post_ok('/user/me/settings/TEST', json => { bar => 'baz' })
        ->status_is(400)
        ->json_is({ error => "Setting key in request payload must match name in the URL ('TEST')" });

    $t->post_ok('/user/me/settings', json => { TEST => undef })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', [ { path => '/TEST', message => re(qr/expected string.*got null/i) } ]);

    $t->post_ok('/user/me/settings/TEST', json => { TEST => undef })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', [ { path => '/TEST', message => re(qr/expected string.*got null/i) } ]);

    $t->post_ok('/user/me/settings/TEST', json => { TEST => { foo => 'bar' } })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', [ { path => '/TEST', message => re(qr/expected string.*got object/i) } ]);

    $t->post_ok('/user/me/settings/TEST', json => { TEST => 'TEST2' })
        ->status_is(204);

    $t->get_ok('/user/me/settings')
        ->status_is(200)
        ->json_schema_is('UserSettings')
        ->json_is({ TEST => 'TEST2' });

    $t->delete_ok('/user/me/settings/TEST')
        ->status_is(204);

    $t->get_ok('/user/me/settings')
        ->status_is(200)
        ->json_schema_is('UserSettings')
        ->json_is({});

    $t->get_ok('/user/me/settings/TEST')
        ->status_is(404);

    $t->post_ok('/user/me/settings/dot.setting', json => { 'dot.setting' => 'set' })
        ->status_is(204);

    $t->get_ok('/user/me/settings/dot.setting')
        ->status_is(200)
        ->json_schema_is('UserSetting')
        ->json_is({ 'dot.setting' => 'set' });

    $t->delete_ok('/user/me/settings/dot.setting')
        ->status_is(204);

    # everything should be deactivated now.
    # starting over, let's see if set_settings overwrites everything...

    $t->post_ok('/user/me/settings', json => { TEST1 => 'TEST', TEST2 => 'ohhai' })
        ->status_is(204);

    $t->post_ok('/user/me/settings', json => { TEST1 => 'test1', TEST3 => 'test3' })
        ->status_is(204);

    $t->get_ok('/user/me/settings')
        ->status_is(200)
        ->json_schema_is('UserSettings')
        ->json_is({
            TEST1 => 'test1',
            TEST3 => 'test3',
        });

    $t->authenticate(email => $ro_user->email);
    my @login_token = ($t->tx->res->json->{jwt_token});
    {
        my $t2 = Test::Conch->new(pg => $t->pg);
        $t2->get_ok('/user/me', { Authorization => 'Bearer '.$login_token[0] })
            ->status_is(200, 'login token works without cookies etc')
            ->json_schema_is('UserDetailed')
            ->json_cmp_deeply({
                id => $ro_user->id,
                name => $ro_user->name,
                email => $ro_user->email,
                created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
                last_login => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
                last_seen => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
                refuse_session_auth => JSON::PP::false,
                force_password_change => JSON::PP::false,
                is_admin => JSON::PP::false,
                organizations => [ {
                    (map +($_ => $organization->$_), qw(id name description)),
                    role => 'admin',
                } ],
                workspaces => [ {
                    (map +($_ => $child_ws->$_), qw(id name description)),
                    parent_workspace_id => undef,   # user does not have the role to see GLOBAL
                    role => 'ro',
                } ],
                builds => [
                    { (map +($_ => $build1->$_), qw(id name description)), role => 'rw', role_via_organization_id => $organization->id },
                    { (map +($_ => $build1->$_), qw(id name description)), role => 'ro' },
                    { (map +($_ => $build2->$_), qw(id name description)), role => 'ro', role_via_organization_id => $organization->id },
                ],
            });
        $user_detailed = $t2->tx->res->json;
        # the superuser always sees parent workspace ids
        $user_detailed->{workspaces}[0]{parent_workspace_id} = $child_ws->parent_workspace_id;
    }

    $t->get_ok('/user')
        ->status_is(403)
        ->log_debug_is('User must be system admin');

    $t_super->get_ok('/user/me')
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_cmp_deeply({
            id => $super_user->id,
            name => $super_user->name,
            email => $super_user->email,
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            last_login => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            last_seen => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            refuse_session_auth => JSON::PP::false,
            force_password_change => JSON::PP::false,
            is_admin => JSON::PP::true,
            organizations => [],
            workspaces => [],
            builds => [],
        });
    $super_user_data = $t_super->tx->res->json;

    $t_super->get_ok('/user')
        ->status_is(200)
        ->json_schema_is('UsersDetailed')
        ->json_cmp_deeply([
            (map +{
                $_->%*,
                last_login => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
                last_seen => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            }, $super_user_data, $user_detailed),
        ]);

    # get another JWT
    $ro_user->update({ password => '123' });
    $t->post_ok('/login', json => { email => $ro_user->email, password => '123' })
        ->status_is(200);
    push @login_token, $t->tx->res->json->{jwt_token};
    {
        my $t2 = Test::Conch->new(pg => $t->pg);
        $t2->get_ok('/user/me', { Authorization => 'Bearer '.$login_token[1] })
            ->status_is(200, 'second login token works without cookies etc')
            ->json_schema_is('UserDetailed')
            ->json_cmp_deeply({
                $user_detailed->%*,
                workspaces => [ map +{ $_->%*, parent_workspace_id => undef }, $user_detailed->{workspaces}->@* ],
                last_login => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
                last_seen => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            });
    }

    {
        my $t2 = Test::Conch->new(pg => $t->pg);
        $t2->get_ok('/user/me', { Authorization => 'Bearer '.$login_token[0] })
            ->status_is(200, 'and first login token still works')
            ->json_schema_is('UserDetailed')
            ->json_cmp_deeply({
                $user_detailed->%*,
                workspaces => [ map +{ $_->%*, parent_workspace_id => undef }, $user_detailed->{workspaces}->@* ],
                last_login => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
                last_seen => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            });
    }

    $t->post_ok('/user/me/token', json => { name => 'an api token' })
        ->status_is(201)
        ->location_is('/user/me/token/an api token');
    my $api_token = $t->tx->res->json->{token};

    $t->post_ok('/user/me/password', json => { password => 'øƕḩẳȋ' })
        ->status_is(204, 'changed password')
        ->email_not_sent;

    $t->get_ok('/user/me/settings')
        ->status_is(401, 'session tokens revoked too')
        ->log_debug_is('auth failed: no credentials provided');

    $t->post_ok('/login', json => { email => $ro_user->email, password => '123' })
        ->status_is(401)
        ->log_debug_is('password validation for '.$ro_user->email.' failed');

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
            ->json_cmp_deeply({
                $user_detailed->%*,
                workspaces => [ map +{ $_->%*, parent_workspace_id => undef }, $user_detailed->{workspaces}->@* ],
                last_login => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
                last_seen => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            });
    }

    $t->post_ok('/login', json => { email => $ro_user->email, password => 'øƕḩẳȋ' })
        ->status_is(200)
        ->log_info_is('user ro_user ('.$ro_user->email.') logged in');

    $t->post_ok('/user/me/password?clear_tokens=all', json => { password => 'another password' })
        ->status_is(204, 'changed password again');

    {
        my $t2 = Test::Conch->new(pg => $t->pg);
        $t2->get_ok('/user/me', { Authorization => 'Bearer '.$api_token })
            ->status_is(401, 'api login token no longer works either');
    }

    $t->post_ok('/login', json => { user_id => $user_detailed->{id}, password => 'another password' })
        ->status_is(200, 'logged in using second new password, and user_id instead of email');

    $t->post_ok('/user/me/password', json => { password => '123' })
        ->status_is(204, 'changed password back to original');

    $t->post_ok('/login', json => { email => $ro_user->email, password => '123' })
        ->status_is(200, 'logged in using original password');

    $t->get_ok('/user/me/settings')
        ->status_is(200, 'original password works again');

    # reset db password entry to '' so we don't have to remember our password string
    $ro_user->discard_changes;
    # FIXME: needs https://rt.cpan.org/Ticket/Display.html?id=130144 or DBICPPC workaround
    #$ro_user->update({ password => Authen::Passphrase::AcceptAll->new });
    $ro_user->store_column('password', ''); # literal AcceptAll crypt value
    $ro_user->make_column_dirty('password');
    $ro_user->update;
};

subtest 'Log out' => sub {
    $t->post_ok('/logout')
        ->status_is(204);
    $t->get_ok('/workspace')
        ->status_is(401);
};

subtest 'JWT authentication' => sub {
    $t->authenticate(email => $ro_user->email, bailout => 0)
        ->json_has('/jwt_token');

    my $jwt_token = $t->tx->res->json->{jwt_token};

    $t->reset_session;  # force JWT to be used to authenticate
    $t->get_ok('/workspace', { Authorization => 'Bearer '.$jwt_token })
        ->status_is(200, 'user can provide Authentication header with full JWT to authenticate');

    $t->reset_session;
    # we're going to be cheeky here and hack the JWT to doctor it...
    # this only works because we have access to the symmetric secret embedded in the app.
    my $jwt_claims = Mojo::JWT->new(secret => $t->app->secrets->[0])->decode($jwt_token);
    my $bad_user_id = create_uuid_str();
    my $hacked_jwt_token = Mojo::JWT->new(
        claims => { $jwt_claims->%{token_id}, user_id => $bad_user_id },
        secret => $t->app->secrets->[0],
        expires => $jwt_claims->{exp},
    )->encode;
    $t->get_ok('/workspace', { Authorization => 'Bearer '.$hacked_jwt_token })
        ->status_is(401, 'the user_id is verified in the JWT');
    $t->log_debug_is('auth failed: JWT for user_id '.$bad_user_id.' could not be found');

    $t->post_ok('/refresh_token', { Authorization => 'Bearer '.$jwt_token })
        ->status_is(200)
        ->json_has('/jwt_token');

    my $new_jwt_token = $t->tx->res->json->{jwt_token};
    $t->get_ok('/workspace', { Authorization => 'Bearer '.$new_jwt_token })
        ->status_is(200, 'Can authenticate with new token');
    $t->get_ok('/workspace', { Authorization => 'Bearer '.$jwt_token })
        ->status_is(401, 'Cannot use old token');

    $t->get_ok('/me', { Authorization => 'Bearer '.$jwt_token })
        ->status_is(401, 'Cannot reuse old JWT');

    $t_super->get_ok('/me', { Authorization => 'Bearer '.$new_jwt_token })
        ->status_is(401, 'cannot use other user\'s JWT')
        ->json_is({ error => 'user session is invalid' });

    $t_super->post_ok('/user/'.$ro_user->email.'/revoke?login_only=1&api_only=1')
        ->status_is(400)
        ->json_schema_is('QueryParamsValidationError')
        ->json_cmp_deeply('/details', [ { path => '/', message => re(qr{allOf/1 should not match}i) } ])
        ->email_not_sent;

    $t_super->post_ok('/user/'.$ro_user->email.'/revoke?api_only=1')
        ->status_is(204, 'Revoke api tokens for user')
        ->email_not_sent;

    $t->get_ok('/workspace', { Authorization => 'Bearer '.$new_jwt_token })
        ->status_is(200, 'user can still use the login token');

    $t_super->post_ok('/user/'.$ro_user->email.'/revoke')
        ->status_is(204, 'Revoke all tokens for user')
        ->email_cmp_deeply([
            {
                To => '"'.$ro_user->name.'" <'.$ro_user->email.'>',
                From => 'noreply@conch.joyent.us',
                Subject => 'Your Conch tokens have been revoked',
                body => re(qr/The following tokens at Joyent Conch have been reset:\R\R    1 login token\R\RYou should now log into https:\/\/conch\.joyent\.us using your login credentials\./m),
            },
        ]);

    $t->get_ok('/workspace', { Authorization => "Bearer $new_jwt_token" })
        ->status_is(401, 'Cannot use after user revocation');
    $t->post_ok('/refresh_token', { Authorization => "Bearer $new_jwt_token" })
        ->status_is(401, 'Cannot use after user revocation');

    $t->authenticate(email => $ro_user->email, bailout => 0);
    my $jwt_token_2 = $t->tx->res->json->{jwt_token};
    $t->post_ok('/user/me/revoke', { Authorization => "Bearer $jwt_token_2" })
        ->status_is(204, 'Revoke tokens for self')
        ->email_not_sent;
    $t->get_ok('/workspace', { Authorization => "Bearer $jwt_token_2" })
        ->status_is(401, 'Cannot use after self revocation');

    $t->authenticate(email => $ro_user->email);
};

my $new_user_data;
subtest 'modify another user' => sub {
    $t->post_ok('/user')
        ->status_is(403)
        ->log_debug_is('User must be system admin');

    $t_super->post_ok('/user', json => { name => 'me', email => 'foo@conch.joyent.us' })
        ->status_is(400, 'user name "me" is prohibited')
        ->json_is({ error => 'user name "me" is prohibited' })
        ->email_not_sent;

    $t_super->post_ok('/user', json => { email => 'foo/bar@conch.joyent.us', name => 'foo' })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', [ { path => '/email', message => re(qr/does not match/i) } ])
        ->email_not_sent;

    $t_super->post_ok('/user', json => { email => 'foo@joyent-com', name => 'foo' })
        ->status_is(400)
        ->json_is({ error => 'user email "foo@joyent-com" is not a valid RFC822 address' })
        ->email_not_sent;

    $t_super->post_ok('/user', json => { name => 'foo', email => $ro_user->email })
        ->status_is(409, 'cannot create user with a duplicate email address')
        ->json_schema_is('UserError')
        ->json_is({
                error => 'duplicate user found',
                user => {
                    (map +($_ => $ro_user->$_), qw(id email name created)),
                    deactivated => undef,
                }
            })
        ->email_not_sent;

    $t_super->post_ok('/user',
            json => { name => $ro_user->name, email => uc($ro_user->email) })
        ->status_is(409, 'emails are not case sensitive when checking for duplicate users')
        ->json_schema_is('UserError')
        ->json_is({
                error => 'duplicate user found',
                user => {
                    (map +($_ => $ro_user->$_), qw(id email name created)),
                    deactivated => undef,
                }
            })
        ->email_not_sent;

    $t_super->post_ok('/user',
            json => { email => 'untrusted@conch.joyent.us', name => 'untrusted', password => '123' })
        ->status_is(201, 'created new user untrusted')
        ->json_schema_is('NewUser')
        ->json_cmp_deeply({
            id => re(Conch::UUID::UUID_FORMAT),
            email => 'untrusted@conch.joyent.us',
            name => 'untrusted',
        })
        ->email_cmp_deeply({
            To => '"untrusted" <untrusted@conch.joyent.us>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Welcome to Conch!',
            body => re(qr/\R\R^\s*Username:\s+untrusted\R^\s*Email:\s+untrusted\@conch\.joyent\.us\R^\s*Password:\s+123\R\R/m),
        });

    $t_super->location_is('/user/'.(my $new_user_id = $t_super->tx->res->json->{id}));
    my $new_user = $t_super->app->db_user_accounts->find($new_user_id);

    $t_super->get_ok("/user/$new_user_id")
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_like('/created', qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/, 'timestamp in RFC3339')
        ->json_is('', {
            id => $new_user_id,
            name => 'untrusted',
            email => 'untrusted@conch.joyent.us',
            created => $new_user->created,
            last_login => undef,
            last_seen => undef,
            refuse_session_auth => JSON::PP::false,
            force_password_change => JSON::PP::false,
            is_admin => JSON::PP::false,
            organizations => [],
            workspaces => [],
            builds => [],
        }, 'returned all the right fields (and not the password)');

    $new_user_data = $t_super->tx->res->json;

    $t_super->get_ok('/user')
        ->status_is(200)
        ->json_schema_is('UsersDetailed')
        ->json_cmp_deeply([
            (map +{
                $_->%*,
                last_login => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
                last_seen => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            }, $super_user_data, $user_detailed),
            $new_user_data,
        ]);

    $t_super->post_ok('/user?send_mail=0',
            json => { email => 'untrusted@conch.joyent.us', name => 'untrusted', password => '123' })
        ->status_is(409, 'cannot create the same user again')
        ->json_schema_is('UserError')
        ->json_is({
            error => 'duplicate user found',
            user => { $new_user_data->%{qw(id email name created deactivated)} },
        });

    $t_super->post_ok('/user?send_mail=0',
            json => { email => 'test_user@conch.joyent.us', name => 'test user', password => '123' })
        ->status_is(201, 'created new user test_user')
        ->location_like(qr!^/user/${\Conch::UUID::UUID_FORMAT}$!)
        ->json_schema_is('NewUser')
        ->json_cmp_deeply({
            id => re(Conch::UUID::UUID_FORMAT),
            email => 'test_user@conch.joyent.us',
            name => 'test user',
        })
        ->email_not_sent;

    $t_super->post_ok('/user/untrusted@conch.joyent.us', json => { email => 'test_user@conch.joyent.us' })
        ->status_is(409)
        ->json_cmp_deeply({
            error => 'duplicate user found',
            user => superhashof({
                email => 'test_user@conch.joyent.us',
                name => 'test user',
                deactivated => undef,
            }),
        })
        ->email_not_sent;

    $t_super->post_ok('/user/untrusted@conch.joyent.us', json => { email => 'foo@joyent-com' })
        ->status_is(400)
        ->json_is({ error => 'user email "foo@joyent-com" is not a valid RFC822 address' })
        ->email_not_sent;

    $t_super->post_ok('/user/untrusted@conch.joyent.us',
            json => { name => 'UNTRUSTED', is_admin => JSON::PP::true })
        ->status_is(303)
        ->location_is('/user/'.$new_user_id)
        ->email_cmp_deeply({
            To => '"UNTRUSTED" <untrusted@conch.joyent.us>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch account has been updated',
            body => re(qr/^Your account at Joyent Conch has been updated:\R\R {4}is_admin: false -> true\R {8}name: untrusted -> UNTRUSTED\R\R/m),
        });
    $new_user_data->{name} = 'UNTRUSTED';
    $new_user_data->{is_admin} = JSON::PP::true;

    $t_super->get_ok($t_super->tx->res->headers->location)
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is($new_user_data);

    my $t2 = Test::Conch->new(pg => $t->pg);
    $t2->post_ok('/login', json => { email => 'untrusted@conch.joyent.us', password => '123' })
        ->status_is(200, 'new user can log in');
    my $jwt_token = $t2->tx->res->json->{jwt_token};

    $t2->get_ok('/me')->status_is(204);

    $t2->post_ok('/user/me/token', json => { name => 'my api token' })
        ->status_is(201)
        ->location_is('/user/me/token/my api token');
    my $api_token = $t2->tx->res->json->{token};

    $t2->post_ok('/user/me/token', json => { name => 'my second api token' })
        ->status_is(201)
        ->location_is('/user/me/token/my second api token');

    $t_super->post_ok("/user/$new_user_id/revoke?login_only=1")
        ->status_is(204, 'revoked login tokens for the new user')
        ->email_cmp_deeply({
            To => '"UNTRUSTED" <untrusted@conch.joyent.us>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch tokens have been revoked',
            body => re(qr/^The following tokens at Joyent Conch have been reset:\R\R    1 login token\R\R/m),
        });

    $t2->get_ok('/me')
        ->status_is(401, 'persistent session cleared when login tokens are revoked');

    $t2->get_ok('/me', { Authorization => 'Bearer '.$jwt_token })
        ->status_is(401, 'new user cannot authenticate with the login JWT after login tokens are revoked');

    $t2->get_ok('/me', { Authorization => 'Bearer '.$api_token })
        ->status_is(204, 'new user can still use the api token');


    $t_super->post_ok("/user/$new_user_id/revoke?api_only=1")
        ->status_is(204, 'revoked api tokens for the new user')
        ->email_cmp_deeply({
            To => '"UNTRUSTED" <untrusted@conch.joyent.us>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch tokens have been revoked',
            body => re(qr/^The following tokens at Joyent Conch have been reset:\R\R    my api token\R    my second api token\R/m),
        });

    $t2->get_ok('/me', { Authorization => "Bearer $api_token" })
        ->status_is(401, 'new user cannot authenticate with the api token after api tokens are revoked');

    $t2->post_ok('/login', json => { email => 'untrusted@conch.joyent.us', password => '123' })
        ->status_is(200, 'new user can still log in again');
    $jwt_token = $t2->tx->res->json->{jwt_token};

    $t2->get_ok('/me')->status_is(204, 'session token re-established');

    $t2->post_ok('/user/me/token', json => { name => 'my api token' })
        ->status_is(201, 'got a new api token')
        ->location_is('/user/me/token/my api token');
    $api_token = $t2->tx->res->json->{token};

    $t2->reset_session; # force JWT to be used to authenticate
    $t2->get_ok('/me', { Authorization => 'Bearer '.$jwt_token })
        ->status_is(204, 'new JWT established');


    # in order to get the user's new password, we need to extract it from a method call before
    # we forget it -- so we pull it out of the call to UserAccount->update.
    use Class::Method::Modifiers 'before';
    my $_new_password;
    before 'Conch::DB::Result::UserAccount::update' => sub {
        $_new_password = $_[1]->{password} if exists $_[1]->{password};
    };

    $t_super->delete_ok('/user/foobar/password')
        ->status_is(400)
        ->json_is({ error => 'invalid identifier format for foobar' });

    $t_super->delete_ok('/user/foobar/password')
        ->status_is(400)
        ->json_is({ error => 'invalid identifier format for foobar' });

    $t_super->delete_ok('/user/foobar@conch.joyent.us/password')
        ->status_is(404, 'attempted to reset the password for a non-existent user');

    $t_super->delete_ok("/user/$new_user_id/password")
        ->status_is(204, 'reset the new user\'s password')
        ->email_cmp_deeply({
            To => '"UNTRUSTED" <untrusted@conch.joyent.us>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch password has changed',
            body => re(qr/^Your password at Joyent Conch has been reset..*\R\R    Username: UNTRUSTED\R    Email:    untrusted\@conch.joyent.us\R    Password: .*\R/ms),
        });

    $t_super->delete_ok('/user/UNTRUSTED@CONCH.JOYENT.US/password')
        ->status_is(204, 'reset the new user\'s password again, with case insensitive email lookup')
        ->email_cmp_deeply({
            To => '"UNTRUSTED" <untrusted@conch.joyent.us>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch password has changed',
            body => re(qr/^Your password at Joyent Conch has been reset..*\R\R    Username: UNTRUSTED\R    Email:    untrusted\@conch.joyent.us\R    Password: .*\R\R/ms),
        });
    my $insecure_password = $_new_password;

    $t2->get_ok('/me')
        ->status_is(401)
        ->log_debug_is('auth failed: no credentials provided');

    $t2->reset_session; # force JWT to be used to authenticate
    $t2->get_ok('/me', { Authorization => 'Bearer '.$jwt_token })
        ->status_is(401)
        ->log_debug_is('auth failed: JWT for user_id '.$new_user_id.' could not be found');

    $t2->get_ok('/user/me', { Authorization => 'Bearer '.$api_token })
        ->status_is(200, 'but the api token still works after his password is changed')
        ->json_schema_is('UserDetailed')
        ->json_cmp_deeply({
            $new_user_data->%*,
            last_login => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            last_seen => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            refuse_session_auth => JSON::PP::true,
            force_password_change => JSON::PP::true,
        });

    $t2->post_ok('/login', json => { email => 'untrusted@conch.joyent.us', password => 'untrusted' })
        ->status_is(401)
        ->log_debug_is('password validation for untrusted@conch.joyent.us failed');

    $t2->post_ok('/login', json => { email => 'untrusted@conch.joyent.us', password => $insecure_password })
        ->status_is(200)
        ->log_info_is('user UNTRUSTED (untrusted@conch.joyent.us) logging in with one-time insecure password')
        ->location_is('/user/me/password');
    $jwt_token = $t2->tx->res->json->{jwt_token};

    $t2->get_ok('/me')
        ->status_is(401)
        ->log_debug_is('attempt to authenticate before changing insecure password')
        ->location_is('/user/me/password');

    $t2->reset_session; # force JWT to be used to authenticate
    $t2->get_ok('/me', { Authorization => 'Bearer '.$jwt_token })
        ->status_is(401)
        ->log_debug_is('attempt to authenticate before changing insecure password')
        ->location_is('/user/me/password');

    $t2->post_ok('/login', json => { email => 'untrusted@conch.joyent.us', password => $insecure_password })
        ->status_is(401)
        ->log_debug_is('password validation for untrusted@conch.joyent.us failed');

    $t2->post_ok('/user/me/password' => { Authorization => 'Bearer '.$jwt_token },
            json => { password => 'a more secure password' })
        ->status_is(204)
        ->log_debug_is('updated password for user UNTRUSTED at their request');

    my $secure_password = $_new_password;
    is($secure_password, 'a more secure password', 'provided password was saved to the db');

    $t2->post_ok('/login', json => { email => 'untrusted@conch.joyent.us', password => $secure_password })
        ->status_is(200)
        ->log_info_is('user UNTRUSTED (untrusted@conch.joyent.us) logged in')
        ->json_has('/jwt_token')
        ->json_hasnt('/message');
    $jwt_token = $t2->tx->res->json->{jwt_token};

    $t2->get_ok('/me')
        ->status_is(204)
        ->log_debug_is('using session user='.$new_user_id)
        ->log_debug_is('looking up user by id '.$new_user_id.': found UNTRUSTED (untrusted@conch.joyent.us)');
    is($t2->tx->res->body, '', '...with no extra response messages');

    $t2->reset_session; # force JWT to be used to authenticate
    $t2->get_ok('/me', { Authorization => 'Bearer '.$jwt_token })
        ->status_is(204)
        ->log_debug_is('attempting to authenticate with Authorization: Bearer header...')
        ->log_debug_is('looking up user by id '.$new_user_id.': found UNTRUSTED (untrusted@conch.joyent.us)');
    is($t2->tx->res->body, '', '...with no extra response messages');


    $t_super->delete_ok('/user/foobar@joyent.conch.us')
        ->status_is(404, 'attempted to deactivate a non-existent user');

    $new_user->create_related('user_workspace_roles', { workspace_id => $child_ws->id, role => 'rw' });

    $t_super->delete_ok("/user/$new_user_id")
        ->status_is(204)
        ->log_warn_is('user '.$super_user->name.' deactivating user UNTRUSTED, direct member of workspaces: child_ws (rw)');

    $t_super->get_ok("/user/$new_user_id")
        ->status_is(404);

    # we haven't cleared the user's session yet...
    $t2->get_ok('/me')
        ->status_is(401)
        ->log_debug_is('auth failed: no credentials provided');

    $t2->reset_session; # force JWT to be used to authenticate
    $t2->post_ok('/login', json => { email => 'untrusted@conch.joyent.us', password => $secure_password })
        ->status_is(401, 'user can no longer log in with credentials');

    $t_super->delete_ok("/user/$new_user_id")
        ->status_is(410, 'new user was already deactivated')
        ->json_schema_is('UserError')
        ->json_cmp_deeply({
            error => 'user was already deactivated',
            user => {
                $new_user_data->%{qw(id email name created)},
                deactivated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            },
        });

    $new_user->discard_changes;
    ok($new_user->deactivated, 'user still exists, but is marked deactivated');

    $t_super->post_ok('/user?send_mail=0',
            json => { email => 'untrusted@conch.joyent.us', name => 'UNTRUSTED', password => '123' })
        ->status_is(201)
        ->location_is('/user/'.(my $second_new_user_id = $t_super->tx->res->json->{id}));
    $t_super->json_is({
            id => $second_new_user_id,
            name => 'UNTRUSTED',
            email => 'untrusted@conch.joyent.us',
        })
        ->log_info_is('created user: UNTRUSTED, email: untrusted@conch.joyent.us, id: '.$second_new_user_id);

    isnt($second_new_user_id, $new_user_id, 'created user with a new id');
    my $second_new_user = $t_super->app->db_user_accounts->find($second_new_user_id);
    is($second_new_user->email, $new_user->email, '...but the email addresses are the same');
    is($second_new_user->name, $new_user->name, '...but the names are the same');


    $t2->post_ok('/logout')->status_is(204);

    my $untrusted_user = $t2->generate_fixtures('user_account');
    $t2->authenticate(email => $untrusted_user->email);

    my $EMAIL = 'conch@conch.joyent.us';
    my @queries = (
        [ GET => '/user' ],
        [ GET => '/user/'.$EMAIL ],
        [ POST => '/user', json => { email => $EMAIL, name => 'test' } ],
        [ POST => '/user/'.$EMAIL, json => json => { name => 'hi' } ],
        [ POST => '/user/'.$EMAIL, json => { is_admin => JSON::PP::true } ],
        [ DELETE => '/user/'.$EMAIL ],
        [ POST => '/user/'.$EMAIL.'/revoke' ],
        [ DELETE => '/user/'.$EMAIL.'/password' ],
        [ GET => '/user/'.$EMAIL.'/token' ],
        [ GET => '/user/'.$EMAIL.'/token/foo' ],
        [ DELETE => '/user/'.$EMAIL.'/token/foo' ],
    );
    $t2->_build_ok($_->@*)->status_is(403)->log_debug_is('User must be system admin')
        foreach @queries;


    warnings(sub {
        memory_cycle_ok($t2, 'no leaks in the Test::Conch object');
    });
};

subtest 'user tokens (our own)' => sub {
    $t->authenticate(email => $ro_user->email);   # make sure we have an unexpired JWT

    $t->get_ok('/user/me/token')
        ->status_is(200)
        ->json_schema_is('UserTokens')
        ->json_cmp_deeply([]);

    my @login_tokens = $super_user->user_session_tokens->login_only->unexpired->all;

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
        ->status_is(409)
        ->json_is({ error => 'name "my first 💩 // to.ken @@" is already in use' });

    my $t2 = Test::Conch->new(pg => $t->pg);
    $t2->get_ok('/user/me', { Authorization => 'Bearer '.$jwt })
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_cmp_deeply({
            $user_detailed->%*,
            workspaces => [ map +{ $_->%*, parent_workspace_id => undef }, $user_detailed->{workspaces}->@* ],
            last_login => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            last_seen => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        });
    undef $t2;

    cmp_deeply(
        $t->app->db_user_session_tokens->search({ name => 'my first 💩 // to.ken @@' })
            ->as_epoch('last_used')->get_column('last_used')->single,
        within_tolerance(time, plus_or_minus => 10),
        'token was last used approximately now',
    );

    $t->delete_ok('/user/me/token/my first 💩 // to.ken @@')
        ->status_is(204);

    $t->get_ok('/user/me/token/my first 💩 // to.ken @@')
        ->status_is(404);

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
    $t->authenticate(email => $ro_user->email);
};

subtest 'user tokens (someone else\'s)' => sub {
    my ($email, $password) = ('untrusted@conch.joyent.us', 'neupassword');

    $t->get_ok('/user/'.$email.'/token')
        ->status_is(403)
        ->log_debug_is('User must be system admin');

    $t_super->get_ok('/user/'.$email.'/token')
        ->status_is(200)
        ->json_schema_is('UserTokens')
        ->json_is([]);

    # password was set to something random when the user was (re)created
    $t->app->db_user_accounts->active->find({ email => $email })->update({ password => $password });

    my $t_other_user = Test::Conch->new(pg => $t->pg);
    $t_other_user->authenticate(email => $email, password => $password);

    $t_other_user->post_ok('/user/me/token', json => { name => 'my first 💩 // to.ken @@' })
        ->status_is(201)
        ->json_schema_is('NewUserToken')
        ->location_is('/user/me/token/my first 💩 // to.ken @@');
    my @jwts = $t_other_user->tx->res->json->{token};

    $t_super->get_ok('/user/'.$email.'/token')
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
    my @tokens = $t_super->tx->res->json->@*;

    $t_super->get_ok('/user/'.$email.'/token/'.$tokens[0]->{name})
        ->status_is(200)
        ->json_schema_is('UserToken')
        ->json_is($tokens[0]);

    # can't use the sysadmin endpoints, even to ask about ourself
    $t_other_user->get_ok('/user/'.$email.'/token')
        ->status_is(403)
        ->log_debug_is('User must be system admin');
    $t_other_user->get_ok('/user/'.$email.'/token/foo')
        ->status_is(403)
        ->log_debug_is('User must be system admin');
    $t_other_user->delete_ok('/user/'.$email.'/token/foo')
        ->status_is(403)
        ->log_debug_is('User must be system admin');

    $t_other_user->post_ok('/user/me/token', json => { name => 'my second token' })
        ->status_is(201)
        ->json_schema_is('NewUserToken')
        ->location_is('/user/me/token/my second token');
    push @jwts, $t_other_user->tx->res->json->{token};

    $t_super->get_ok('/user/'.$email.'/token')
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
    @tokens = $t_super->tx->res->json->@*;

    $t_super->delete_ok('/user/'.$email.'/token/'.$tokens[0]->{name})
        ->status_is(204);

    $t_super->get_ok('/user/'.$email.'/token')
        ->status_is(200)
        ->json_schema_is('UserTokens')
        ->json_is([ $tokens[1] ]);

    $t_super->get_ok('/user/'.$email.'/token/'.$tokens[0]->{name})
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

    $t_super->post_ok('/user/'.$email.'/revoke')
        ->status_is(204)
        ->email_cmp_deeply({
            To => '"UNTRUSTED" <'.$email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch tokens have been revoked',
            body => re(qr/^The following tokens at Joyent Conch have been reset:\R\R    my second token\R    1 login token\R\R/m),
        });

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

    $t_super->delete_ok('/user/'.$email.'/token/'.$tokens[0]->{name})
        ->status_is(404);

    $t_super->delete_ok('/user/'.$email.'/token/'.$tokens[1]->{name})
        ->status_is(404);

    $t_super->get_ok('/user/'.$email.'/token')
        ->status_is(200)
        ->json_schema_is('UserTokens')
        ->json_is([]);

    $t_other_user->get_ok('/user/me', { Authorization => 'Bearer '.$jwts[0] })
        ->status_is(401, 'first token is gone');

    $t_other_user->get_ok('/user/me', { Authorization => 'Bearer '.$jwts[1] })
        ->status_is(401, 'second token is gone');

    is(
        $t_super->app->db_user_accounts->active->search({ email => $email })
            ->related_resultset('user_session_tokens')->count,
        0,
        'both tokens are now deleted',
    );
};

warnings(sub {
    memory_cycle_ok($t, 'no leaks in the Test::Conch object');
});

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
