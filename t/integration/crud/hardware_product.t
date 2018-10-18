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

$t->get_ok("/db/hardware_product")->status_is(200)
	->json_schema_is("DBHardwareProducts");

my $hw_id = $t->tx->res->json->[0]->{id};
my $vendor_id = $t->tx->res->json->[0]->{vendor};

$t->get_ok("/db/hardware_product/$hw_id")->status_is(200)
	->json_schema_is("DBHardwareProduct");

$t->post_ok("/db/hardware_product", json => {
	wat => 'wat',
})->status_is(400)->json_schema_is("Error");

$t->post_ok("/db/hardware_product", json => {
	name => 'sungo',
	vendor => $vendor_id,
	alias => 'sungo',
})->status_is(303);

$t->get_ok($t->tx->res->headers->location)->status_is(200)
	->json_schema_is("DBHardwareProduct");

my $id = $t->tx->res->json->{id};

$t->post_ok("/db/hardware_product", json => {
	name => 'sungo',
	vendor => $vendor_id,
	alias => 'sungo',
})->status_is(400)->json_schema_is("Error");

$t->post_ok("/db/hardware_product/$id", json => {
	id => $id,
	name => 'sungo2',
})->status_is(303);

$t->get_ok($t->tx->res->headers->location)->status_is(200)
	->json_schema_is("DBHardwareProduct");

$t->get_ok("/db/hardware_product/name=sungo")->status_is(404);

$t->get_ok("/db/hardware_product/name=sungo2")->status_is(200)
	->json_schema_is("DBHardwareProduct");

$t->delete_ok("/db/hardware_product/$id")->status_is(204);
$t->get_ok("/db/hardware_product/$id")->status_is(404);


$t->get_ok("/hardware_product")
	->status_is(200)
	->json_schema_is('HardwareProducts');

$t->get_ok("/hardware_product/$hw_id")
	->status_is(200)
	->json_schema_is('HardwareProduct');

done_testing();
