use strict;
use warnings;

use Test::Conch;
use Test::More;
use Test::Warnings;
use Test::Deep;

my $t = Test::Conch->new(pg => undef);

$t->get_ok('/ping')
    ->status_is(200)
    ->json_schema_is('Ping')
    ->json_is({ status => 'ok' });

$t->get_ok('/ping', { 'User-Agent' => 'Mozilla/5.0' })
    ->status_is(200);

$t->get_ok('/ping', { 'User-Agent' => 'Mozilla/5.0 Macintosh', 'X-Conch-UI' => 'v3.0.2.1-gdeadbeef' })
    ->status_is(403)
    ->log_warn_is('Conch UI too old: requires at least 4.x')
    ->log_info_is(superhashof({
            req => superhashof({
                user => 'NOT AUTHED',
                headers => superhashof({
                    'User-Agent' => [ 'Mozilla/5.0 Macintosh' ],
                    'X-Conch-UI' => [ 'v3.0.2.1-gdeadbeef' ],
                }),
                url => str('/ping'),
            }),
            res => superhashof({ statusCode => 403 }),
        }), 'we still logged the request');

$t->get_ok('/ping', { 'User-Agent' => 'Mozilla/5.0 Macintosh', 'x-conch-ui' => 'v3.0.2.1-gdeadbeef' })
    ->status_is(403)
    ->log_warn_is('Conch UI too old: requires at least 4.x');

$t->get_ok('/ping', { 'User-Agent' => 'Mozilla/5.0 Macintosh', 'X-Conch-UI' => 'v4.0.0.3.gdeadbeef' })
    ->status_is(200);

$t->get_ok('/ping', { 'User-Agent' => 'conch shell v1.11.11-v1.11-0-g0ad9598' })
    ->status_is(403)
    ->log_warn_is('Conch Shell too old');

$t->get_ok('/ping', { 'User-Agent' => 'Conch/0.0.0 ConchShell/blahblah...' })
    ->status_is(403)
    ->log_warn_is('Conch Shell too old');

$t->get_ok('/ping', { 'User-Agent' => 'Conch/3.12.0 ConchShell/blahblah...' })
    ->status_is(200);

$t->get_ok('/version', { 'User-Agent' => 'Conch/0.0.0 ConchShell/blahblah...' })
    ->status_is(200);

done_testing;
