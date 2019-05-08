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
$t->load_fixture('conch_user_global_workspace');

$t->post_ok('/login', json => { email => 'a', password => 'b' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/email', message => re(qr/does not match/i) } ]);

$t->post_ok('/login', json => { email => 'foo@bar.com' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/password', message => re(qr/missing property/i) } ]);

$t->post_ok('/login', json => { email => 'foo@bar.com', password => 'b' })
    ->status_is(401);

my $now = Conch::Time->now;

$t->authenticate;

isa_ok($t->tx->res->cookie('conch'), 'Mojo::Cookie::Response');

my $conch_user = $t->app->db_user_accounts->search({ name => $t->CONCH_USER })->single;

ok($conch_user->last_login >= $now, 'user last_login is updated')
    or diag('last_login not updated: '.$conch_user->last_login.' is not updated to '.$now);


subtest 'User' => sub {
    $t->get_ok('/me')
        ->status_is(204);

    $t->get_ok('/user/me/settings')
        ->status_is(200)
        ->json_schema_is('UserSettings')
        ->json_is({});

    $t->get_ok('/user/me/settings/BAD')
        ->status_is(404);

    $t->post_ok('/user/me/settings/TEST', json => { NOTTEST => 'test' })
        ->status_is(400)
        ->json_is({ error => "Setting key in request object must match name in the URL ('TEST')" });

    $t->post_ok('/user/me/settings/FOO/BAR', json => { 'FOO/BAR' => 1 })
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

    $t->post_ok('/user/me/settings/TEST2', json => { TEST2 => { foo => 'bar' } })
        ->status_is(204);

    $t->get_ok('/user/me/settings/TEST2')
        ->status_is(200)
        ->json_schema_is('UserSetting')
        ->json_is({ TEST2 => { foo => 'bar' } });

    $t->get_ok('/user/me/settings')
        ->status_is(200)
        ->json_schema_is('UserSettings')
        ->json_is({ TEST => 'TEST', TEST2 => { foo => 'bar' } });

    $t->delete_ok('/user/me/settings/TEST')
        ->status_is(204);

    $t->get_ok('/user/me/settings')
        ->status_is(200)
        ->json_schema_is('UserSettings')
        ->json_is({ TEST2 => { foo => 'bar' } });

    $t->delete_ok('/user/me/settings/TEST2')
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
    my $user_id;
    {
        my $t2 = Test::Conch->new(pg => $t->pg);
        $t2->get_ok('/user/me', { Authorization => 'Bearer '.$login_token[1] })
            ->status_is(200, 'second login token works without cookies etc')
            ->json_schema_is('UserDetailed')
            ->json_is('/email' => $t2->CONCH_EMAIL);
        $user_id = $t2->tx->res->json->{id};
    }

    {
        my $t2 = Test::Conch->new(pg => $t->pg);
        $t2->get_ok('/user/me', { Authorization => 'Bearer '.$login_token[0] })
            ->status_is(200, 'and first login token still works')
            ->json_schema_is('UserDetailed')
            ->json_is('/email' => $t2->CONCH_EMAIL);
    }

    $t->post_ok('/user/me/token', json => { name => 'an api token' })
        ->status_is(201)
        ->location_is('/user/me/token/an api token');
    my $api_token = $t->tx->res->json->{token};

    $t->post_ok('/user/me/password', json => { password => 'øƕḩẳȋ' })
        ->status_is(204, 'changed password')
        ->email_not_sent;

    $t->get_ok('/user/me/settings')
        ->status_is(401, 'session tokens revoked too');

    $t->post_ok('/login', json => { email => $t->CONCH_EMAIL, password => $t->CONCH_PASSWORD })
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

    $t->post_ok('/login', json => { email => $t->CONCH_EMAIL, password => 'øƕḩẳȋ' })
        ->status_is(200, 'logged in using new password');

    $t->post_ok('/user/me/password?clear_tokens=all', json => { password => 'another password' })
        ->status_is(204, 'changed password again');

    {
        my $t2 = Test::Conch->new(pg => $t->pg);
        $t2->get_ok('/user/me', { Authorization => 'Bearer '.$api_token })
            ->status_is(401, 'api login token no longer works either');
    }

    $t->post_ok('/login', json => { user_id => $user_id, password => 'another password' })
        ->status_is(200, 'logged in using second new password, and user_id instead of email');

    $t->post_ok('/user/me/password', json => { password => $t->CONCH_PASSWORD })
        ->status_is(204, 'changed password back to original');

    $t->post_ok('/login', json => { email => $t->CONCH_EMAIL, password => $t->CONCH_PASSWORD })
        ->status_is(200, 'logged in using original password');

    $t->get_ok('/user/me/settings')
        ->status_is(200, 'original password works again');
};

subtest 'Log out' => sub {
    $t->post_ok('/logout')
        ->status_is(204);
    $t->get_ok('/workspace')
        ->status_is(401);
};

subtest 'JWT authentication' => sub {
    $t->authenticate(bailout => 0)->json_has('/jwt_token');

    my $jwt_token = $t->tx->res->json->{jwt_token};
    my $jwt_sig   = $t->tx->res->cookie('jwt_sig')->value;

    $t->get_ok('/workspace', { Authorization => "Bearer $jwt_token" })
        ->status_is(200, 'user can provide JWT token with cookie to authenticate');
    $t->reset_session;  # force JWT to be used to authenticate
    $t->get_ok('/workspace', { Authorization => "Bearer $jwt_token.$jwt_sig" })
        ->status_is(200, 'user can provide Authentication header with full JWT to authenticate');

    $t->post_ok('/refresh_token', { Authorization => "Bearer $jwt_token.$jwt_sig" })
        ->status_is(200)
        ->json_has('/jwt_token');

    my $new_jwt_token = $t->tx->res->json->{jwt_token};
    $t->get_ok('/workspace', { Authorization => "Bearer $new_jwt_token" })
        ->status_is(200, 'Can authenticate with new token');
    $t->get_ok('/workspace', { Authorization => "Bearer $jwt_token.$jwt_sig" })
        ->status_is(401, 'Cannot use old token');

    $t->get_ok('/me', { Authorization => "Bearer $jwt_token.$jwt_sig" })
        ->status_is(401, 'Cannot reuse old JWT');

    $t->post_ok('/user/'.$t->CONCH_EMAIL.'/revoke?login_only=1&api_only=1',
            { Authorization => 'Bearer '.$new_jwt_token })
        ->status_is(400)
        ->json_schema_is('QueryParamsValidationError')
        ->json_cmp_deeply('/details', [ { path => '/', message => re(qr{allOf/1 should not match}i) } ])
        ->email_not_sent;

    $t->post_ok('/user/'.$t->CONCH_EMAIL.'/revoke?api_only=1',
            { Authorization => 'Bearer '.$new_jwt_token })
        ->status_is(204, 'Revoke api tokens for user')
        ->email_not_sent;

    $t->get_ok('/workspace', { Authorization => 'Bearer '.$new_jwt_token })
        ->status_is(200, 'user can still use the login token');

    $t->post_ok('/user/'.$t->CONCH_EMAIL.'/revoke',
            { Authorization => "Bearer $new_jwt_token" })
        ->status_is(204, 'Revoke all tokens for user')
        ->email_not_sent;

    $t->get_ok('/workspace', { Authorization => "Bearer $new_jwt_token" })
        ->status_is(401, 'Cannot use after user revocation');
    $t->post_ok('/refresh_token', { Authorization => "Bearer $new_jwt_token" })
        ->status_is(401, 'Cannot use after user revocation');

    $t->authenticate(bailout => 0);
    my $jwt_token_2 = $t->tx->res->json->{jwt_token};
    $t->post_ok('/user/me/revoke', { Authorization => "Bearer $jwt_token_2" })
        ->status_is(204, 'Revoke tokens for self')
        ->email_not_sent;
    $t->get_ok('/workspace', { Authorization => "Bearer $jwt_token_2" })
        ->status_is(401, 'Cannot use after self revocation');

    $t->authenticate;
};

subtest 'modify another user' => sub {
    $t->post_ok('/user', json => { name => 'me', email => 'foo@conch.joyent.us' })
        ->status_is(400, 'user name "me" is prohibited')
        ->json_is({ error => 'user name "me" is prohibited' })
        ->email_not_sent;

    $t->post_ok('/user', json => { name => 'foo', email => $t->CONCH_EMAIL })
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
            })
        ->email_not_sent;

    $t->post_ok('/user',
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
            })
        ->email_not_sent;

    $t->post_ok('/user',
            json => { email => 'foo@conch.joyent.us', name => 'foo', password => '123' })
        ->status_is(201, 'created new user foo')
        ->json_schema_is('NewUser')
        ->json_has('/id', 'got user id')
        ->json_is('/email' => 'foo@conch.joyent.us', 'got email')
        ->json_is('/name' => 'foo', 'got name')
        ->email_cmp_deeply({
            To => '"foo" <foo@conch.joyent.us>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Welcome to Conch!',
            body => re(qr/\R\R^\s*Username:\s+foo\R^\s*Email:\s+foo\@conch\.joyent\.us\R^\s*Password:\s+123\R\R/m),
        });

    $t->location_is('/user/'.(my $new_user_id = $t->tx->res->json->{id}));
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

    $t->post_ok('/user?send_mail=0',
            json => { email => 'test_user@conch.joyent.us', name => 'test user', password => '123' })
        ->status_is(201, 'created new user test_user')
        ->location_like(qr!^/user/${\Conch::UUID::UUID_FORMAT}!)
        ->json_schema_is('NewUser')
        ->json_cmp_deeply({
            id => re(Conch::UUID::UUID_FORMAT),
            email => 'test_user@conch.joyent.us',
            name => 'test user',
        })
        ->email_not_sent;

    $t->post_ok('/user/foo@conch.joyent.us', json => { email => 'test_user@conch.joyent.us' })
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

    $t->post_ok('/user/foo@conch.joyent.us',
            json => { name => 'FOO', is_admin => JSON::PP::true })
        ->status_is(303)
        ->location_is('/user/'.$new_user_id)
        ->email_cmp_deeply({
            To => '"FOO" <foo@conch.joyent.us>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch account has been updated.',
            body => re(qr/^Your account at Joyent Conch has been updated:\R\R {4}is_admin: false -> true\R {8}name: foo -> FOO\R\R/m),
        });
    $t->get_ok($t->tx->res->headers->location)
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is({
            $new_user_data->%*,
            name => 'FOO',
            is_admin => JSON::PP::true,
        });

    my $t2 = Test::Conch->new(pg => $t->pg);
    $t2->post_ok('/login', json => { email => 'foo@conch.joyent.us', password => '123' })
        ->status_is(200, 'new user can log in');
    my $jwt_token = $t2->tx->res->json->{jwt_token};
    my $jwt_sig   = $t2->tx->res->cookie('jwt_sig')->value;

    $t2->get_ok('/me')->status_is(204);

    $t2->post_ok('/user/me/token', json => { name => 'my api token' })
        ->status_is(201)
        ->location_is('/user/me/token/my api token');
    my $api_token = $t2->tx->res->json->{token};

    $t2->post_ok('/user/me/token', json => { name => 'my second api token' })
        ->status_is(201)
        ->location_is('/user/me/token/my second api token');

    $t->post_ok("/user/$new_user_id/revoke?login_only=1")
        ->status_is(204, 'revoked login tokens for the new user')
        ->email_cmp_deeply({
            To => '"FOO" <foo@conch.joyent.us>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch tokens have been revoked.',
            body => re(qr/^The following tokens at Joyent Conch have been reset:\R\R    1 login token\R\R/m),
        });

    $t2->get_ok('/me')
        ->status_is(401, 'persistent session cleared when login tokens are revoked');

    $t2->get_ok('/me', { Authorization => "Bearer $jwt_token.$jwt_sig" })
        ->status_is(401, 'new user cannot authenticate with the login JWT after login tokens are revoked');

    $t2->get_ok('/me', { Authorization => 'Bearer '.$api_token })
        ->status_is(204, 'new user can still use the api token');


    $t->post_ok("/user/$new_user_id/revoke?api_only=1")
        ->status_is(204, 'revoked api tokens for the new user')
        ->email_cmp_deeply({
            To => '"FOO" <foo@conch.joyent.us>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch tokens have been revoked.',
            body => re(qr/^The following tokens at Joyent Conch have been reset:\R\R    my api token\R    my second api token\R/m),
        });

    $t2->get_ok('/me', { Authorization => "Bearer $api_token" })
        ->status_is(401, 'new user cannot authenticate with the api token after api tokens are revoked');

    $t2->post_ok('/login', json => { email => 'foo@conch.joyent.us', password => '123' })
        ->status_is(200, 'new user can still log in again');
    $jwt_token = $t2->tx->res->json->{jwt_token};
    $jwt_sig   = $t2->tx->res->cookie('jwt_sig')->value;

    $t2->get_ok('/me')->status_is(204, 'session token re-established');

    $t2->post_ok('/user/me/token', json => { name => 'my api token' })
        ->status_is(201, 'got a new api token')
        ->location_is('/user/me/token/my api token');
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

    $t->delete_ok('/user/foobar/password')
        ->status_is(400)
        ->json_is({ error => 'invalid identifier format for foobar' });

    $t->delete_ok('/user/foobar/password')
        ->status_is(400)
        ->json_is({ error => 'invalid identifier format for foobar' });

    $t->delete_ok('/user/foobar@conch.joyent.us/password')
        ->status_is(404, 'attempted to reset the password for a non-existent user');

    $t->delete_ok("/user/$new_user_id/password")
        ->status_is(204, 'reset the new user\'s password')
        ->email_cmp_deeply({
            To => '"FOO" <foo@conch.joyent.us>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch password has changed.',
            body => re(qr/^Your password at Joyent Conch has been reset..*\R\R    Username: FOO\R    Email:    foo\@conch.joyent.us\R    Password: .*\R/ms),
        });

    $t->delete_ok('/user/FOO@CONCH.JOYENT.US/password')
        ->status_is(204, 'reset the new user\'s password again, with case insensitive email lookup')
        ->email_cmp_deeply({
            To => '"FOO" <foo@conch.joyent.us>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch password has changed.',
            body => re(qr/^Your password at Joyent Conch has been reset..*\R\R    Username: FOO\R    Email:    foo\@conch.joyent.us\R    Password: .*\R\R/ms),
        });
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

    $t2->post_ok('/login', json => { email => 'foo@conch.joyent.us', password => 'foo' })
        ->status_is(401, 'cannot log in with the old password');

    $t2->post_ok('/login', json => { email => 'foo@conch.joyent.us', password => $insecure_password })
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

    $t2->post_ok('/login', json => { email => 'foo@conch.joyent.us', password => $insecure_password })
        ->status_is(401, 'user cannot log in with the same insecure password again');

    $t2->post_ok('/user/me/password' => { Authorization => "Bearer $jwt_token.$jwt_sig" },
            json => { password => 'a more secure password' })
        ->status_is(204, 'user finally acquiesced and changed his password');

    my $secure_password = $_new_password;
    is($secure_password, 'a more secure password', 'provided password was saved to the db');

    $t2->post_ok('/login', json => { email => 'foo@conch.joyent.us', password => $secure_password })
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


    $t->delete_ok('/user/foobar@joyent.conch.us')
        ->status_is(404, 'attempted to deactivate a non-existent user');

    $t->delete_ok("/user/$new_user_id")
        ->status_is(204, 'new user is deactivated');

    # we haven't cleared the user's session yet...
    $t2->get_ok('/me')
        ->status_is(401, 'user cannot log in with saved browser session');

    $t2->reset_session; # force JWT to be used to authenticate
    $t2->post_ok('/login', json => { email => 'foo@conch.joyent.us', password => $secure_password })
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
    $t->location_is('/user/'.(my $second_new_user_id = $t->tx->res->json->{id}));

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
        ->status_is(409)
        ->json_is({ error => 'name "my first 💩 // to.ken @@" is already in use' });

    my $t2 = Test::Conch->new(pg => $t->pg);
    $t2->get_ok('/user/me', { Authorization => 'Bearer '.$jwt })
        ->status_is(200)
        ->json_schema_is('UserDetailed')
        ->json_is('/email' => $t2->CONCH_EMAIL);
    undef $t2;

    $t->delete_ok('/user/me/token/my first 💩 // to.ken @@')
        ->status_is(204);

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

    $t->get_ok('/user/'.$email.'/token')
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

    $t->get_ok('/user/'.$email.'/token')
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

    $t->get_ok('/user/'.$email.'/token/'.$tokens[0]->{name})
        ->status_is(200)
        ->json_schema_is('UserToken')
        ->json_is($tokens[0]);

    # can't use the sysadmin endpoints, even to ask about ourself
    $t_other_user->get_ok('/user/'.$email.'/token')
        ->status_is(403);
    $t_other_user->get_ok('/user/'.$email.'/token/foo')
        ->status_is(403);
    $t_other_user->delete_ok('/user/'.$email.'/token/foo')
        ->status_is(403);

    $t_other_user->post_ok('/user/me/token', json => { name => 'my second token' })
        ->status_is(201)
        ->json_schema_is('NewUserToken')
        ->location_is('/user/me/token/my second token');
    push @jwts, $t_other_user->tx->res->json->{token};

    $t->get_ok('/user/'.$email.'/token')
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

    $t->delete_ok('/user/'.$email.'/token/'.$tokens[0]->{name})
        ->status_is(204);

    $t->get_ok('/user/'.$email.'/token')
        ->status_is(200)
        ->json_schema_is('UserTokens')
        ->json_is([ $tokens[1] ]);

    $t->get_ok('/user/'.$email.'/token/'.$tokens[0]->{name})
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

    $t->post_ok('/user/'.$email.'/revoke')
        ->status_is(204)
        ->email_cmp_deeply({
            To => '"FOO" <'.$email.'>',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch tokens have been revoked.',
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

    $t->delete_ok('/user/'.$email.'/token/'.$tokens[0]->{name})
        ->status_is(404);

    $t->delete_ok('/user/'.$email.'/token/'.$tokens[1]->{name})
        ->status_is(404);

    $t->get_ok('/user/'.$email.'/token')
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

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
