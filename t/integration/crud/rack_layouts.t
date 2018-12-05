use Mojo::Base -strict;
use Test::More;
use Test::Warnings;
use Data::UUID;
use Test::Conch;

my $t = Test::Conch->new;
$t->load_fixture('legacy_datacenter');

my $uuid = Data::UUID->new;

$t->post_ok(
    '/login' => json => {
        user     => 'conch@conch.joyent.us',
        password => 'conch',
    }
)->status_is(200);
BAIL_OUT('Login failed') if $t->tx->res->code != 200;

my $fake_id = $uuid->create_str();

$t->get_ok('/layout')
    ->status_is(200)
    ->json_schema_is('RackLayouts');

my $initial_layouts = $t->tx->res->json;
my $layout_width_4 = $initial_layouts->[2];    # start 7, width 4.

$t->get_ok("/layout/$initial_layouts->[0]{id}")
    ->status_is(200)
    ->json_schema_is('RackLayout')
    ->json_is('', $initial_layouts->[0]);

$t->post_ok('/layout', json => { wat => 'wat' })
    ->status_is(400);

$t->get_ok('/rack')
    ->status_is(200)
    ->json_schema_is('Racks');
my $rack_id = $t->tx->res->json->[0]{id};

$t->get_ok('/hardware_product')
    ->status_is(200)
    ->json_schema_is('HardwareProducts');
my $hw_product_id = $t->tx->res->json->[0]{id};

$t->get_ok("/rack/$rack_id/layouts")
    ->status_is(200)
    ->json_schema_is('RackLayouts');

$t->post_ok('/layout', json => {
        rack_id => $fake_id,
        product_id => $hw_product_id,
        ru_start => 42,
    })
    ->status_is(400)
    ->json_schema_is('Error');

$t->post_ok('/layout', json => {
        rack_id => $rack_id,
        product_id => $fake_id,
        ru_start => 42,
    })
    ->status_is(400)
    ->json_schema_is('Error');

$t->post_ok('/layout', json => {
        rack_id => $rack_id,
        product_id => $hw_product_id,
        ru_start => 42
    })
    ->status_is(303);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('RackLayout');
my $layout_id = $t->tx->res->json->{id};

$t->post_ok('/layout', json => {
        rack_id => $rack_id,
        product_id => $hw_product_id,
        ru_start => 42
    })
    ->status_is(400)
    ->json_schema_is('Error');

$t->get_ok("/rack/$rack_id/layouts")
    ->status_is(200)
    ->json_schema_is('RackLayouts');

# at the moment, we have these occupied slots:
# start 1, width 2
# start 3, width 2
# start 7, width 4
# start 42, width 1

# can't put something into an occupied position
$t->post_ok("/layout/$layout_id", json => { ru_start => 7 })
    ->status_is(400)
    ->json_is({ error => 'ru_start conflict' });

# the start of this product will overlap with occupied slots (need 8-11, 7-10 are occupied)
$t->post_ok("/layout/$layout_id", json => { ru_start => 8 })
    ->status_is(400)
    ->json_is({ error => 'ru_start conflict' });

# the end of this product will overlap with occupied slots (need 6-9, 7-10 are occupied)
$t->post_ok("/layout/$layout_id",
        json => { ru_start => 6, product_id => $layout_width_4->{product_id} })
    ->status_is(400)
    ->json_is({ error => 'ru_start conflict' });

$t->post_ok("/layout/$layout_id",
        json => { ru_start => 19, product_id => $layout_width_4->{product_id} })
    ->status_is(303)
    ->location_is("/layout/$layout_id");

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_is('/ru_start' => 19)
    ->json_schema_is('RackLayout');

$t->post_ok("/layout/$layout_id", json => { rack_id => $fake_id })
    ->status_is(400)
    ->json_schema_is('Error');

$t->post_ok("/layout/$layout_id", json => { product_id => $fake_id })
    ->status_is(400)
    ->json_schema_is('Error');

$t->post_ok('/layout', json => {
        rack_id => $rack_id,
        product_id => $hw_product_id,
        ru_start => 42
    })
    ->status_is(303);

$t->post_ok("/layout/$layout_id", json => { ru_start => 42 })
    ->status_is(400)
    ->json_schema_is('Error');

$t->delete_ok("/layout/$layout_id")
    ->status_is(204);
$t->get_ok("/layout/$layout_id")
    ->status_is(404);

done_testing();
# vim: set ts=4 sts=4 sw=4 et :
