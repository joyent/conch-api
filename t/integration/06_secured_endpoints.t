use strict;
use warnings;

use Test::More;
use Data::UUID;
use Test::Warnings;
use Test::Conch;

my $uuid = Data::UUID->new;

my $t = Test::Conch->new;

$t->get_ok('/ping')->status_is(200);

$t->get_ok('/me')->status_is(401);
$t->get_ok('/workspace')->status_is(401);
$t->get_ok('/workspace/'.$uuid->create_str)->status_is(401);

$t->get_ok('/device/TEST')->status_is(401);
$t->post_ok('/device/TEST', json => { a => 'b' })->status_is(401);

$t->post_ok('/relay/TEST/register', json => { a => 'b' })->status_is(401);

$t->get_ok('/user/me/settings')->status_is(401);
$t->post_ok('/user/me/settings', json => { a => 'b' })->status_is(401);
$t->get_ok('/user/me/settings/test')->status_is(401);
$t->post_ok('/user/me/settings/test', json => { a => 'b' })->status_is(401);
$t->get_ok('/user/me/settings/test.dot')->status_is(401);
$t->post_ok('/user/me/settings/test.dot', json => { 'test.dot' => 'b' })->status_is(401);

$t->get_ok('/hardware_product')->status_is(401);
$t->get_ok('/hardware_product/'.$uuid->create_str)->status_is(401);

done_testing;
