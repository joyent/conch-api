use strict;
use warnings;
use utf8;

use Test::Mojo;
use Test::More;
use Data::UUID;
use IO::All;

use Data::Printer;

BEGIN {
	use_ok("Test::ConchTmpDB");
	use_ok( "Conch::Route", qw(all_routes) );
}

my $uuid = Data::UUID->new;

my $pgtmp = mk_tmp_db() or BAIL_OUT("failed to create test database");
my $dbh = DBI->connect( $pgtmp->dsn );

my $t = Test::Mojo->new(
	Conch => {
		pg      => $pgtmp->uri,
		secrets => ["********"]
	}
);

all_routes( $t->app->routes );

$t->get_ok("/ping")->status_is(200)->json_is( '/status' => 'ok' );

$t->get_ok("/me")->status_is(401)->json_is( '/error' => 'unauthorized' );
$t->get_ok("/login")->status_is(401)->json_is( '/error' => 'unauthorized' );
$t->post_ok("/feedback", json => { a => 'b' })->status_is(401)->json_is( '/error' => 'unauthorized' );

$t->get_ok("/workspace")->status_is(401)->json_is( '/error' => 'unauthorized' );
$t->get_ok( "/workspace/" . $uuid->create_str )->status_is(401)
	->json_is( '/error' => 'unauthorized' );

$t->get_ok("/device/TEST")->status_is(401)
	->json_is( '/error' => 'unauthorized' );
$t->post_ok("/device/TEST", json => { a => 'b' })->status_is(401)
	->json_is( '/error' => 'unauthorized' );

$t->post_ok("/relay/TEST/register", json => { a => 'b' })->status_is(401)
	->json_is( '/error' => 'unauthorized' );

$t->get_ok("/user/me/settings")->status_is(401)
	->json_is( '/error' => 'unauthorized' );
$t->post_ok("/user/me/settings", json => { a => 'b' })->status_is(401)
	->json_is( '/error' => 'unauthorized' );
$t->get_ok("/user/me/settings/test")->status_is(401)
	->json_is( '/error' => 'unauthorized' );
$t->post_ok("/user/me/settings/test", json => { a => 'b' })->status_is(401)
	->json_is( '/error' => 'unauthorized' );

$t->get_ok("/hardware_product")->status_is(401)
	->json_is( '/error' => 'unauthorized' );
$t->get_ok("/hardware_product/" . $uuid->create_str)->status_is(401)
	->json_is( '/error' => 'unauthorized' );

done_testing();
