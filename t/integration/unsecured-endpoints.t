use v5.26;
use warnings;

use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;
use Conch::UUID 'create_uuid_str';

my $t = Test::Conch->new;

$t->get_ok('/ping')
    ->status_is(200)
    ->json_schema_is('Ping')
    ->json_is({ status => 'ok' })
    ->header_exists('Request-Id')
    ->header_exists('X-Request-ID')
    ->header_is('X-Conch-API', $t->app->version_tag);

$t->get_ok('/me')->status_is(401);

$t->get_ok('/version')
    ->status_is(200)
    ->header_is('Last-Modified', $t->app->startup_time->strftime('%a, %d %b %Y %T GMT'))
    ->json_schema_is('Version')
    ->json_cmp_deeply({ version => re(qr/^v/) });

$t->get_ok('/foo/bar/baz')
    ->status_is(404)
    ->json_is({ error => 'Route Not Found' })
    ->log_warn_is('no endpoint found for: GET /foo/bar/baz');

$t->post_ok('/boop?some_arg=1')
    ->status_is(404)
    ->json_is({ error => 'Route Not Found' })
    ->log_warn_is('no endpoint found for: POST /boop');

$t->get_ok('/organization')->status_is(401);
$t->get_ok('/organization/'.create_uuid_str())->status_is(401);

$t->get_ok('/device/TEST')->status_is(401);
$t->post_ok('/device_report', json => { a => 'b' })->status_is(401);

$t->post_ok('/relay/TEST/register', json => { a => 'b' })->status_is(401);

$t->get_ok('/hardware_product')->status_is(401);
$t->get_ok('/hardware_product/'.create_uuid_str())->status_is(401);

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
