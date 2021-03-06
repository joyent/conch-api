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
use Test::Fatal;
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

open my $access_log_fh, '>:raw', \my $access_log_file or die "cannot open to scalarref: $!";

my $api_version_re = qr/^${ Test::Conch->API_VERSION_RE }$/;

{
    like(
        exception {
            Test::Conch->new(config => {
                logging => { level => 'whargarbl' },
                features => { no_db => 1 },
            })
        },
        qr/unrecognized log level whargarbl/,
        'reject bad log levels',
    );
}

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
        re(qr/^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{5}] \[$$\] \[info\] this is a 💩 info message 0/),
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

sub add_test_routes ($t) {
    my $r = Mojolicious::Routes->new;

    $r->get('/_hello', sub ($c) {
        $c->log->warn('this is a warn message');
        $c->log->debug('this is a debug message');
        $c->status(204);
    });
    $r->post('/_error', { query_params_schema => 'Anything', request_schema => 'Anything' }, sub ($c) {
        $c->log->error('error line from controller');
        $c->status(400, { error => 'something bad happened' });
    });
    $r->post('/_die', { query_params_schema => 'Anything', request_schema => 'Anything' }, sub ($c) { die 'ach, I am slain' });
    $t->add_routes($r);

    return (warn => __LINE__-11, debug => __LINE__-10, error => __LINE__-6, die => __LINE__-3);
}

{
    reset_log;

    cmp_deeply(
        Test::Conch->new(config => { features => { no_db => 1 }, logging => { verbose => 0 } })->app->log,
        all(
            isa('Conch::Log'),
            methods(
                path => str(Path::Tiny->cwd->child('log/test.log')),
                bunyan => 1,
                with_trace => 0,
            ),
        ),
        'logger via $app gets good default options',
    );

    local $ENV{MOJO_MODE} = 'foo';
    cmp_deeply(
        Test::Conch->new(config => { features => { no_db => 1 }, logging => { verbose => 0 } })->app->log,
        all(
            isa('Conch::Log'),
            methods(
                path => str(Path::Tiny->cwd->child('log/foo.log')),
                bunyan => 1,
                with_trace => 0,
            ),
        ),
        'logger via $app uses MOJO_MODE for filename',
    );
}

{
    reset_log;
    my $t = Test::Conch->new(config => {
        logging => { handle => $log_fh, access_log_handle => $access_log_fh, verbose => 0 },
        features => { validate_all_responses => 0 },
    });

    cmp_deeply(
        $t->app->log,
        all(
            isa('Conch::Log'),
            methods(
                handle => ignore,
                bunyan => 1,
                with_trace => 0,
            ),
        ),
        'logger via $app gets filehandle',
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
    $t->app->some_helper;

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

    reset_log;
    my %lines = add_test_routes($t);

    $t->get_ok('/_hello')
        ->status_is(204);

    my $request_id = $t->tx->res->headers->header('Request-Id');
    cmp_ok(length($request_id), '>=', 12, 'request_id has some heft to it');

    $t->log_warn_is('this is a warn message');
    $t->log_debug_is('this is a debug message');
    $t->log_is('this is a warn message');
    $t->log_is('this is a debug message');

    my $dispatch_data = +{
        level => 'info',
        msg => 'dispatch',
        api_version => re($api_version_re),
        latency => re(qr/^\d+$/),
        req => {
            user        => 'NOT AUTHED',
            method      => 'GET',
            url         => '/_hello',
            remoteAddress => '127.0.0.1',
            remotePort  => ignore,
            headers     => superhashof({}),
            query_params => {},
        },
        res => {
            headers => superhashof({}),
            statusCode => 204,
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
                    msg => re(qr/204 NO CONTENT/i),
                },
                # final dispatch line
                $dispatch_data,
            ),
        ],
        'our controller logged two messages in bunyan format, with the request id',
    );

    cmp_deeply(
        [ split(/\n/, $access_log_file) ],
        [ re(qr{^127.0.0.1 - - \[\d\d/\w+/\d{4}:\d\d:\d\d:\d\d [-+]\d{4}\] "GET /_hello HTTP/1\.1" 204 -$}) ],
        'access log has one line',
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

    $t->get_ok('/_hello')
        ->status_is(204);

    $request_id = $t->tx->res->headers->header('Request-Id');

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
                    msg => re(qr/204 NO CONTENT/i),

                },
                # final dispatch line
                $dispatch_data,
            ),
        ],
        'our controller logged two messages in bunyan format with trace and request id; dispatch line never has trace info',
    );

    $t->post_ok('/_error?query_param=value0', json => { body_param => 'value1' })
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
            api_version => re($api_version_re),
            latency => re(qr/^\d+$/),
            req => {
                user        => 'NOT AUTHED',
                method      => 'POST',
                url         => '/_error?query_param=value0',
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

    $t->post_ok('/_die?query_param=value0', json => { body_param => 'value1' })
        ->status_is(500);
    my $post_line = __LINE__ - 2;

    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file))[-2]),
        my $dispatch = +{
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'info',
            req_id => $t->tx->res->headers->header('Request-Id'),
            msg => 'dispatch',
            api_version => re($api_version_re),
            latency => re(qr/^\d+$/),
            req => {
                user        => 'NOT AUTHED',
                method      => 'POST',
                url         => '/_die?query_param=value0',
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
                msg => re(qr/^ach, I am slain at ${\__FILE__} line $lines{die}\.$/m),
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
                            line => $post_line,
                        },
                        {
                            class => 'main',
                            file => __FILE__,
                            func => ignore,
                            line => $lines{die},
                        },
                    ),
                ),
            },
        },
        'dispatch line for an uncaught exception includes the full stack trace',
    );

    delete $dispatch->@{qw(msg latency)};
    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file))[-1]),
        +{
            $dispatch->%*,
            level => 'error',
        },
        'an uncaught exception is also sent to the exception log',
    );


    $t->post_ok('/login', json => { email => 'foo@example.com', password => 'PASSWORD' })
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
            api_version => re($api_version_re),
            latency => re(qr/^\d+$/),
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

    my $user = $t->load_fixture('super_user');
    $t->authenticate->json_schema_is('LoginToken');

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
            api_version => re($api_version_re),
            latency => re(qr/^\d+$/),
            req => {
                user        => $user->email.' ('.$user->id.')',
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
    my $t = Test::Conch->new(config => { logging => { handle => $log_fh, verbose => 1 }, features => { validate_all_responses => 0 } });

    my %lines = add_test_routes($t);

    $t->post_ok('/_error?query_param=value0', json => { body_param => 'value1' })
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
        'verbose mode turns on trace option',
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
            api_version => re($api_version_re),
            latency => re(qr/^\d+$/),
            req => {
                user        => 'NOT AUTHED',
                method      => 'POST',
                url         => '/_error?query_param=value0',
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
        'dispatch line for an error in verbose mode includes both the request and response body',
    );

    $t->post_ok('/_die?query_param=value0', json => { body_param => 'value1' })
        ->status_is(500);
    my $post_line = __LINE__ - 2;

    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file))[-2]),
        my $dispatch = +{
            name => 'conch-api',
            hostname => $hostname,
            pid => $$,
            time => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            v => 2,
            level => 'info',
            req_id => $t->tx->res->headers->header('Request-Id'),
            msg => 'dispatch',
            api_version => re($api_version_re),
            latency => re(qr/^\d+$/),
            req => {
                user        => 'NOT AUTHED',
                method      => 'POST',
                url         => '/_die?query_param=value0',
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
                msg => re(qr/^ach, I am slain at ${\__FILE__} line $lines{die}\.$/m),
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
                            line => $post_line,
                        },
                        {
                            class => 'main',
                            file => __FILE__,
                            func => ignore,
                            line => $lines{die},
                        },
                    ),
                ),
            },
        },
        'dispatch line for an uncaught exception in verbose mode includes the full stack trace',
    );

    delete $dispatch->@{qw(msg latency)};
    cmp_deeply(
        decode_json((split(/\n/, $fake_log_file))[-1]),
        +{
            $dispatch->%*,
            level => 'error',
        },
        'an uncaught exception is also sent to the exception log',
    );


    $t->post_ok('/login', json => { email => 'foo@example.com', password => 'PASSWORD' })
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
            api_version => re($api_version_re),
            latency => re(qr/^\d+$/),
            req => {
                user        => 'NOT AUTHED',
                method      => 'POST',
                url         => '/login',
                remoteAddress => '127.0.0.1',
                remotePort  => ignore,
                headers     => superhashof({}),
                query_params => {},
                body => { email => 'foo@example.com', password => '--REDACTED--' },
            },
            res => {
                headers => superhashof({}),
                statusCode => 401,
                body => { error => 'Unauthorized' },
            },
        },
        'dispatch line for /login error in verbose mode does NOT contain the request body',
    );

    my $user = $t->load_fixture('super_user');
    $t->authenticate->json_schema_is('LoginToken');

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
            api_version => re($api_version_re),
            latency => re(qr/^\d+$/),
            req => {
                user        => $user->email.' ('.$user->id.')',
                method      => 'POST',
                url         => '/login',
                remoteAddress => '127.0.0.1',
                remotePort  => ignore,
                headers     => superhashof({}),
                query_params => {},
                # Test::Conch::authenticate sets set_session -> true
                body => { email => 'conch@conch.joyent.us', password => '--REDACTED--', set_session => JSON::PP::true },
            },
            res => {
                headers => superhashof({}),
                statusCode => 200,
                body => { jwt_token => '--REDACTED--' },
            },
        },
        'dispatch line for /login success in verbose mode',
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
            api_version => re($api_version_re),
            latency => re(qr/^\d+$/),
            req => {
                user        => $user->email.' ('.$user->id.')',
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
                body => {
                  name => 'my api token',
                  token => '--REDACTED--',
                  (map +($_ => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/)), qw(created expires)),
                  last_used => undef,
                },
            },
        },
        'dispatch line for creating a token in verbose mode does not contain the token string',
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
            api_version => re($api_version_re),
            latency => re(qr/^\d+$/),
            req => {
                user        => $user->email.' ('.$user->id.')',
                method      => 'POST',
                url         => '/user/me/password',
                remoteAddress => '127.0.0.1',
                remotePort  => ignore,
                headers     => superhashof({ Authorization => '--REDACTED--' }),
                query_params => {},
                body => { password => '--REDACTED--' },
            },
            res => {
                headers => superhashof({}),
                statusCode => 204,
                body => '',
            },
        },
        'dispatch line for changing password in verbose mode does not contain the password',
    );
}

done_testing;
