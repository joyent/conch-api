use Mojo::Base -strict;
use Test::More;
use Test::Warnings;
use Data::UUID;

use Test::Conch::Datacenter;

my $t = Test::Conch::Datacenter->new();

my $uuid = Data::UUID->new;

$t->post_ok(
	"/login" => json => {
		user     => 'conch@conch.joyent.us',
		password => 'conch'
	}
)->status_is(200);
BAIL_OUT("Login failed") if $t->tx->res->code != 200;

my $fake_id = $uuid->create_str();

$t->get_ok('/layout')->status_is(200)->json_schema_is('RackLayouts');

my $id = $t->tx->res->json->[0]{id};

$t->get_ok("/layout/$id")->status_is(200)->json_schema_is('RackLayout');

$t->post_ok("/layout", json => {
	wat => 'wat'
})->status_is(400);

$t->get_ok('/rack')->status_is(200)->json_schema_is('Racks');
my $rack_id = $t->tx->res->json->[0]{id};

$t->get_ok("/hardware_product")->status_is(200);
my $hw_product_id = $t->tx->res->json->[0]{id};

$t->get_ok("/rack/$rack_id/layouts")->status_is(200)
	->json_schema_is('RackLayouts');

$t->post_ok("/layout", json => {
	rack_id => $fake_id,
	product_id => $hw_product_id,
	ru_start => 42,
})->status_is(400)->json_schema_is('Error');

$t->post_ok("/layout", json => {
	rack_id => $rack_id,
	product_id => $fake_id,
	ru_start => 42,
})->status_is(400)->json_schema_is('Error');

$t->post_ok("/layout", json => {
	rack_id => $rack_id,
	product_id => $hw_product_id,
	ru_start => 42
})->status_is(303);

$t->get_ok($t->tx->res->headers->location)->status_is(200)
	->json_schema_is('RackLayout');
my $idr = $t->tx->res->json->{id};

$t->post_ok("/layout", json => {
	rack_id => $rack_id,
	product_id => $hw_product_id,
	ru_start => 42
})->status_is(400)->json_schema_is('Error');


$t->get_ok("/rack/$rack_id/layouts")->status_is(200)
	->json_schema_is('RackLayouts');

$t->post_ok("/layout/$idr", json => {
	ru_start => 43
})->status_is(303);

$t->get_ok($t->tx->res->headers->location)->status_is(200)
	->json_is("/ru_start" => 43)
	->json_schema_is('RackLayout');

$t->post_ok("/layout/$idr", json => {
	rack_id => $fake_id
})->status_is(400)->json_schema_is('Error');

$t->post_ok("/layout/$idr", json => {
	product_id => $fake_id
})->status_is(400)->json_schema_is('Error');

$t->post_ok("/layout", json => {
	rack_id => $rack_id,
	product_id => $hw_product_id,
	ru_start => 42
})->status_is(303);

$t->post_ok("/layout/$idr", json => {
	ru_start => 42
})->status_is(400)->json_schema_is('Error');

$t->delete_ok("/layout/$idr")->status_is(204);
$t->get_ok("/layout/$idr")->status_is(404);

done_testing();
