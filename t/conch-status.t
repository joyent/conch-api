use strict;
use warnings;
use experimental 'signatures';

use Test::More;
use Test::Warnings;
use Test::Conch;

sub add_test_routes ($app) {
    $app->routes->get('/301', sub ($c) { $c->status(301, '/301-success') });
    $app->routes->get('/302', sub ($c) { $c->status(302, '/302-success') });
    $app->routes->get('/303', sub ($c) { $c->status(303, '/303-success') });
    $app->routes->get('/307', sub ($c) { $c->status(307, '/307-success') });
    $app->routes->get('/308', sub ($c) { $c->status(308, '/308-success') });

    $app->routes->get('/401', sub ($c) { $c->status(401) });
    $app->routes->get('/403', sub ($c) { $c->status(403) });
    $app->routes->get('/404', sub ($c) { $c->status(404) });
    $app->routes->get('/501', sub ($c) { $c->status(501) });

    $app->routes->get('/200-object', sub ($c) { $c->status(200, { status => 'OK' }) });
    $app->routes->get('/200-array', sub ($c) { $c->status(200, []) });

    $app->routes->get('/409', sub ($c) { $c->status(409, { error => 'Conflict'}) });

    $app->routes->get('/204', sub ($c) { $c->status(204) });
    $app->routes->get('/410', sub ($c) { $c->status(410) });
}


{
    my $t = Test::Conch->new();

    add_test_routes( $t->app );

    $t->get_ok('/301')->status_is('301')->location_is('/301-success');
    $t->get_ok('/302')->status_is('302')->location_is('/302-success');
    $t->get_ok('/303')->status_is('303')->location_is('/303-success');
    $t->get_ok('/307')->status_is('307')->location_is('/307-success');
    $t->get_ok('/308')->status_is('308')->location_is('/308-success');

    $t->get_ok('/401')->status_is('401')->json_is({ error => 'Unauthorized' });
    $t->get_ok('/403')->status_is('403')->json_is({ error => 'Forbidden' });
    $t->get_ok('/404')->status_is('404')->json_is({ error => 'Not Found' });
    $t->get_ok('/501')->status_is('501')->json_is({ error => 'Unimplemented' });

    $t->get_ok('/409')->status_is('409')->json_is({ error => 'Conflict'});

    $t->get_ok('/200-object')->status_is('200')->json_is({ status => 'OK'});
    $t->get_ok('/200-array')->status_is('200')->json_is([]);

    $t->get_ok('/204')->status_is('204')->content_is('');
    $t->get_ok('/410')->status_is('410')->content_is('');
}

done_testing;
