use strict;
use warnings;
use warnings FATAL => 'utf8';
use utf8;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8
use experimental 'signatures';

use Test::More;
use Test::Warnings ':all';
use Test::Deep;
use Test::Deep::NumberTolerant;
use Conch::Log;
use Test::Conch;
use Time::HiRes 'time'; # time() now has µs precision
use Sys::Hostname;
use Mojo::Util 'decode';
use Mojo::JSON 'decode_json';

my $now = time;
my $hostname = Sys::Hostname::hostname;

open my $log_fh, '>:raw', \my $fake_log_file or die "cannot open to scalarref: $!";
sub reset_log { $fake_log_file = ''; seek $log_fh, 0, 0; }

{
    my $regular_log = Conch::Log->new(handle => $log_fh);
    $regular_log->info('this is a 💩 info', 'message 0');

    cmp_deeply(
        [ $regular_log->history->@* ],
        [
            [
                within_tolerance($now, offset => (0, 60)),
                'info',
                'this is a 💩 info',
                'message 0',
            ],
        ],
        'history',
    );

    cmp_deeply(
        decode('UTF-8', $fake_log_file),
        re(qr/^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{5}] \[$$\] \[info\] this is a 💩 info\nmessage/),
        'regular log with no formatting options uses Mojo::Log defaults',
    );


    local $Conch::Log::REQUEST_ID = 'abcde';
    my $bunyan_log = Conch::Log->new(handle => $log_fh, bunyan => 1);
    $bunyan_log->debug('this is a 💩 debug', 'message 1');

    cmp_deeply(
        [ $bunyan_log->history->@* ],
        [
            [
                within_tolerance($now, offset => (0, 60)),
                'debug',
                'this is a 💩 debug',
                'message 1',
            ],
        ],
        'bunyan logger history',
    );

    cmp_deeply(
        # fake_log contains encoded bytes - it has to, because it was written to as a scalar ref.
        decode_json((split(/\n/, $fake_log_file || '{}'))[-1]),
        {
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'debug',
            req_id => 'abcde',
            msg => "this is a 💩 debug\nmessage 1",
        },
        'bunyan format',
    );

    local $Conch::Log::REQUEST_ID = 'deadbeef';
    my $trace_log = Conch::Log->new(handle => $log_fh, bunyan => 1, with_trace => 1);

    package Foo::Bar::Baz {
        sub my_warn($class, $log, @msg) {
            $log->warn(@msg); return __LINE__;
        }
    }

    my $line = Foo::Bar::Baz->my_warn($trace_log, 'this is a 💩 warn', 'message 2');

    cmp_deeply(
        [ $trace_log->history->@* ],
        [
            [
                within_tolerance($now, offset => (0, 60)),
                'warn',
                'this is a 💩 warn',
                'message 2',
            ],
        ],
        'trace logger history',
    );

    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file || '{}'))[-1]),
        {
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'warn',
            req_id => 'deadbeef',
            src => {
                file => __FILE__,
                line => $line,
                func => 'Foo::Bar::Baz::my_warn',
            },
            msg => "this is a 💩 warn\nmessage 2",
        },
        'bunyan format with trace',
    );
}

sub add_test_routes ($app) {
    $app->routes->get('/hello')->to(cb => sub ($c) {
        $c->log->warn('this is a warn message');
        $c->log->debug('this is a debug message');
        $c->status(200);
    });
    $app->routes->post('/error')->to(cb => sub ($c) {
        $c->log->error('error line from controller');
        $c->status(400, { error => 'something bad happened' });
    });
    $app->routes->post('/die')->to(cb => sub ($c) { die 'ach, I am slain' });

    return (warn => __LINE__-10, debug => __LINE__-9, error => __LINE__-5, die => __LINE__-2);
}

{
    reset_log;
    my $t = Test::Conch->new(config => {
        logging => { handle => $log_fh },
        features => { audit => 0 },
    });

    cmp_deeply(
        $t->app->log,
        all(
            isa('Conch::Log'),
            methods(
                path => str(Path::Tiny->cwd->child('log/development.log')),
                bunyan => 1,
                with_trace => 0,
            ),
        ),
        'logger via $app gets good default options',
    );

    $t->app->log->info('info to the app');

    cmp_deeply(
        $t->app->log->history->[-1],
        [
            within_tolerance($now, offset => (0, 60)),
            'info',
            'info to the app',
        ],
        'logged to app logger',
    );

    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file || '{}'))[-1]),
        {
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'info',
            msg => 'info to the app',
        },
        'app-level logging used bunyan format, without trace or request_id',
    );

    $t->app->helper(some_helper => sub ($c) { $c->log->info('info from a helper') });
    $t->app->some_helper();

    cmp_deeply(
        $t->app->log->history->[-1],
        [
            within_tolerance($now, offset => (0, 60)),
            'info',
            'info from a helper',
        ],
        'helper sub can use log helper sub',
    );

    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file || '{}'))[-1]),
        {
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'info',
            msg => 'info from a helper',
        },
        'helper sub called outside a request logged in bunyan format, without trace or request_id',
    );

    my %lines = add_test_routes($t->app);

    $t->get_ok('/hello')
        ->status_is(200);

    my $request_id = $t->tx->res->headers->header('Request-Id');

    $t->log_warn_is('this is a warn message');
    $t->log_debug_is('this is a debug message');
    $t->log_is('this is a warn message');
    $t->log_is('this is a debug message');

    my $dispatch_data = +{
        level => 'info',
        msg => 'dispatch',
        req => {
            user        => 'NOT AUTHED',
            method      => 'GET',
            url         => '/hello',
            remoteAddress => '127.0.0.1',
            remotePort  => ignore,
            headers     => superhashof({}),
            query_params => {},
        },
        res => {
            headers => superhashof({}),
            statusCode => 200,
        },
    };

    cmp_deeply(
        [ map decode_json($_), (split(/\n/, $fake_log_file))[-4...-1] ],
        [
            map +{
                name => 'conch-api',
                hostname => $hostname,
                pid => $$,
                time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
                v => 2,
                req_id => $request_id,
                $_->%*,
            },
            (
                # two manual log messages
                (map +{
                    level => $_,
                    msg => "this is a $_ message",
                }, qw(warn debug)),
                +{
                    # this is the response logged by Mojolicious::Controller
                    level => 'debug',
                    msg => re(qr/200 OK/),
                },
                # final dispatch line
                $dispatch_data,
            ),
        ],
        'our controller logged two messages in bunyan format, with the request id',
    );

    $t->app->log->warn('warn to the app');
    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file || '{}'))[-1]),
        {
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'warn',
            msg => 'warn to the app',
        },
        'app-level logging used bunyan format, without trace or request_id, even after request id set from a controller log line',
    );


    $t->app->log->with_trace(1);

    $t->get_ok('/hello')
        ->status_is(200);

    $request_id = $t->tx->res->headers->header('Request-Id');

    cmp_deeply(
        # skip over final dispatch log line for now
        [ map decode_json($_), (split(/\n/, $fake_log_file))[-4...-1] ],
        [
            map +{
                name => 'conch-api',
                hostname => $hostname,
                pid => $$,
                time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
                v => 2,
                req_id => $request_id,
                $_->%*,
            },
            (
                # two manual log messages
                (map +{
                    level => $_,
                    src => {
                        file => __FILE__,
                        line => $lines{$_},
                        func => re(qr/main::__ANON__/),
                    },
                    msg => "this is a $_ message",
                }, qw(warn debug)),
                +{
                    # this is the response logged by Mojolicious::Controller
                    level => 'debug',
                    src => superhashof({ func => 'Mojolicious::Controller::rendered' }),
                    msg => re(qr/200 OK/),

                },
                # final dispatch line
                $dispatch_data,
            ),
        ],
        'our controller logged two messages in bunyan format with trace and request id; dispatch line never has trace info',
    );

    $t->post_ok('/error?query_param=value0', json => { body_param => 'value1' })
        ->status_is(400);

    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file))[-1]),
        +{
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'info',
            req_id => $t->tx->res->headers->header('Request-Id'),
            msg => 'dispatch',
            req => {
                user        => 'NOT AUTHED',
                method      => 'POST',
                url         => '/error?query_param=value0',
                remoteAddress => '127.0.0.1',
                remotePort  => ignore,
                headers     => superhashof({}),
                query_params => { query_param => 'value0' },
            },
            res => {
                headers => superhashof({}),
                statusCode => 400,
                body => { error => 'something bad happened' },
            },
        },
        'dispatch line for an error includes the response body',
    );

    $t->post_ok('/die?query_param=value0', json => { body_param => 'value1' })
        ->status_is(500);

    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file))[-1]),
        +{
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'info',
            req_id => $t->tx->res->headers->header('Request-Id'),
            msg => 'dispatch',
            req => {
                user        => 'NOT AUTHED',
                method      => 'POST',
                url         => '/die?query_param=value0',
                remoteAddress => '127.0.0.1',
                remotePort  => ignore,
                headers     => superhashof({}),
                query_params => { query_param => 'value0' },
            },
            res => {
                headers => superhashof({}),
                statusCode => 500,
                body => { error => 'An exception occurred' },
            },
            err => {
                msg => 'ach, I am slain at '.__FILE__." line $lines{die}.\n",
                frames => all(
                    array_each({
                        class => ignore,
                        file => ignore,
                        line => re('^\d+$'),
                        func => ignore,
                    }),
                    supersetof(
                        {
                            class => 'main',
                            file => __FILE__,
                            func => 'Test::Mojo::post_ok',
                            line => ignore,
                        },
                        {
                            class => 'main',
                            file => __FILE__,
                            func => re('__ANON__'),
                            line => $lines{die},
                        },
                    ),
                ),
            },
        },
        'dispatch line for an uncaught exception includes the full stack trace',
    );

    $t->post_ok('/login', json => { user => 'foo@example.com', password => 'PASSWORD' })
        ->status_is(401);

    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file))[-1]),
        +{
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'info',
            req_id => $t->tx->res->headers->header('Request-Id'),
            msg => 'dispatch',
            req => {
                user        => 'NOT AUTHED',
                method      => 'POST',
                url         => '/login',
                remoteAddress => '127.0.0.1',
                remotePort  => ignore,
                headers     => superhashof({}),
                query_params => {},
            },
            res => {
                headers => superhashof({}),
                statusCode => 401,
                body => { error => 'Unauthorized' },
            },
        },
        'dispatch line for /login error includes the response body',
    );

    $t->load_fixture('conch_user_global_workspace');
    my $user_id = $t->app->db_user_accounts->search({ email => $t->CONCH_EMAIL })->get_column('id')->single;
    $t->authenticate->json_has('/jwt_token');

    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file))[-1]),
        +{
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'info',
            req_id => $t->tx->res->headers->header('Request-Id'),
            msg => 'dispatch',
            req => {
                user        => $t->CONCH_EMAIL.' ('.$user_id.')',
                method      => 'POST',
                url         => '/login',
                remoteAddress => '127.0.0.1',
                remotePort  => ignore,
                headers     => superhashof({}),
                query_params => {},
            },
            res => {
                headers => superhashof({}),
                statusCode => 200,
            },
        },
        'dispatch line for /login success',
    );
}

{
    reset_log;
    my $t = Test::Conch->new(
        config => {
            logging => { handle => $log_fh },
            features => { audit => 1 },
        },
    );

    my %lines = add_test_routes($t->app);

    $t->post_ok('/error?query_param=value0', json => { body_param => 'value1' })
        ->status_is(400);

    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file || '{}'))[-3]),
        {
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'error',
            req_id => $t->tx->res->headers->header('Request-Id'),
            src => {
                file => __FILE__,
                line => $lines{error},
                func => re(qr/main::__ANON__/),
            },
            msg => 'error line from controller',
        },
        'audit mode turns on trace mode',
    );

    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file || '{}'))[-1]),
        +{
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'info',
            req_id => $t->tx->res->headers->header('Request-Id'),
            msg => 'dispatch',
            req => {
                user        => 'NOT AUTHED',
                method      => 'POST',
                url         => '/error?query_param=value0',
                remoteAddress => '127.0.0.1',
                remotePort  => ignore,
                headers     => superhashof({}),
                query_params => { query_param => 'value0' },
                body        => { body_param => 'value1' },
            },
            res => {
                headers => superhashof({}),
                statusCode => 400,
                body => { error => 'something bad happened' },
            },
        },
        'dispatch line for an error in audit mode includes both the request and response body',
    );

    $t->post_ok('/die?query_param=value0', json => { body_param => 'value1' })
        ->status_is(500);

    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file))[-1]),
        +{
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'info',
            req_id => $t->tx->res->headers->header('Request-Id'),
            msg => 'dispatch',
            req => {
                user        => 'NOT AUTHED',
                method      => 'POST',
                url         => '/die?query_param=value0',
                remoteAddress => '127.0.0.1',
                remotePort  => ignore,
                headers     => superhashof({}),
                query_params => { query_param => 'value0' },
                body        => { body_param => 'value1' },
            },
            res => {
                headers => superhashof({}),
                statusCode => 500,
                body => { error => 'An exception occurred' },
            },
            err => {
                msg => 'ach, I am slain at '.__FILE__." line $lines{die}.\n",
                frames => all(
                    array_each({
                        class => ignore,
                        file => ignore,
                        line => re('^\d+$'),
                        func => ignore,
                    }),
                    supersetof(
                        {
                            class => 'main',
                            file => __FILE__,
                            func => 'Test::Mojo::post_ok',
                            line => ignore,
                        },
                        {
                            class => 'main',
                            file => __FILE__,
                            func => re('__ANON__'),
                            line => $lines{die},
                        },
                    ),
                ),
            },
        },
        'dispatch line for an uncaught exception in audit mode includes the full stack trace',
    );

    $t->post_ok('/login', json => { user => 'foo@example.com', password => 'PASSWORD' })
        ->status_is(401);

    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file))[-1]),
        +{
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'info',
            req_id => $t->tx->res->headers->header('Request-Id'),
            msg => 'dispatch',
            req => {
                user        => 'NOT AUTHED',
                method      => 'POST',
                url         => '/login',
                remoteAddress => '127.0.0.1',
                remotePort  => ignore,
                headers     => superhashof({}),
                query_params => {},
                # no body! that contains the password!!!
            },
            res => {
                headers => superhashof({}),
                statusCode => 401,
                body => { error => 'Unauthorized' },
            },
        },
        'dispatch line for /login error in audit mode does NOT contain the request body',
    );

    $t->get_ok($t->ua->server->url->userinfo('foo@conch.joyent.us:123')->path('/me'))
        ->status_is(401);

    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file))[-1]),
        +{
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'info',
            req_id => $t->tx->res->headers->header('Request-Id'),
            msg => 'dispatch',
            req => {
                user        => 'NOT AUTHED',
                method      => 'GET',
                url         => '/me',
                remoteAddress => '127.0.0.1',
                remotePort  => ignore,
                headers     => superhashof({}),
                query_params => {},
                body        => '',
            },
            res => {
                headers => superhashof({}),
                statusCode => 401,
                body => { error => 'Unauthorized' },
            },
        },
        'dispatch line for basic auth in audit mode does NOT contain the password',
    );

    $t->load_fixture('conch_user_global_workspace');
    my $user_id = $t->app->db_user_accounts->search({ email => $t->CONCH_EMAIL })->get_column('id')->single;
    $t->authenticate->json_has('/jwt_token');

    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file))[-1]),
        +{
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'info',
            req_id => $t->tx->res->headers->header('Request-Id'),
            msg => 'dispatch',
            req => {
                user        => $t->CONCH_EMAIL.' ('.$user_id.')',
                method      => 'POST',
                url         => '/login',
                remoteAddress => '127.0.0.1',
                remotePort  => ignore,
                headers     => superhashof({}),
                query_params => {},
            },
            res => {
                headers => superhashof({}),
                statusCode => 200,
                # no body! that contains the JWT!!!
            },
        },
        'dispatch line for /login success in audit mode',
    );

    $t->post_ok('/user/me/token', json => { name => 'my api token' })
        ->status_is(201)
        ->json_has('/token');

    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file))[-1]),
        +{
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'info',
            req_id => $t->tx->res->headers->header('Request-Id'),
            msg => 'dispatch',
            req => {
                user        => $t->CONCH_EMAIL.' ('.$user_id.')',
                method      => 'POST',
                url         => '/user/me/token',
                remoteAddress => '127.0.0.1',
                remotePort  => ignore,
                headers     => superhashof({}),
                query_params => {},
                body        => { name => 'my api token' },
            },
            res => {
                headers => superhashof({}),
                statusCode => 201,
                # no body! that contains the api token!!!
            },
        },
        'dispatch line for creating a token in audit mode does not contain the token string',
    );

    $t->post_ok('/user/me/password' => { Authorization => 'Bearer '.$t->tx->res->json->{token} },
            json => { password => 'new password' })
        ->status_is(204);

    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file))[-1]),
        +{
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'info',
            req_id => $t->tx->res->headers->header('Request-Id'),
            msg => 'dispatch',
            req => {
                user        => $t->CONCH_EMAIL.' ('.$user_id.')',
                method      => 'POST',
                url         => '/user/me/password',
                remoteAddress => '127.0.0.1',
                remotePort  => ignore,
                headers     => notexists('Authorization'),
                query_params => {},
                # no body! that contains the password!!!
            },
            res => {
                headers => superhashof({}),
                statusCode => 204,
                body => '',
            },
        },
        'dispatch line for changing password in audit mode does not contain the password',
    );
}

# TODO: replace with Test::Deep::notexists($key)
sub notexists
{
    my @keys = @_;
    Test::Deep::code(sub {
        return (0, 'not a HASH') if ref $_[0] ne 'HASH';
        foreach my $key (@keys) {
            return (0, "'$key' key exists") if exists $_[0]->{$key};
        }
        return 1;
    });
}

done_testing;
