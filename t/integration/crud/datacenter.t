use Mojo::Base -strict;
use Test::More;
use Test::Warnings;
use Data::UUID;

use Data::Printer;

BEGIN {
	use_ok("Conch::Models");
}

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

$t->get_ok("/dc")->status_is(200)->json_is('/0/region', 'test-region-1');

my $dc_id = $t->tx->res->json->[0]->{id};
$t->get_ok("/dc/$dc_id")->status_is(200)->json_is('/region', 'test-region-1');

$t->get_ok("/dc/$dc_id/rooms")->status_is(200)->json_is('/0/az', 'test-region-1a');


#########

$t->post_ok('/dc', json => {
	wat => 'wat'
})->status_is(400);

$t->post_ok('/dc', json => {
	vendor => 'vend0r',
	region => 'regi0n',
	location => 'locati0n',
})->status_is(303);

$t->get_ok($t->tx->res->headers->location)->status_is(200);

my $idd = $t->tx->res->json->{id};
$t->post_ok("/dc/$idd", json => {
	vendor => 'vendor',
})->status_is(303);
$t->get_ok($t->tx->res->headers->location)->status_is(200)
	->json_is('/vendor', 'vendor');

$t->delete_ok("/dc/$idd")->status_is(204);
$t->get_ok("/dc/$idd")->status_is(404);

###########

$t->get_ok("/room")->status_is(200)->json_is('/0/az', 'test-region-1a');
my $room_id = $t->tx->res->json->[0]->{id};

$t->get_ok("/room/". $room_id)
	->status_is(200)->json_is('/az', 'test-region-1a');

$t->get_ok("/room/$room_id/racks")->status_is(200)
	->json_is('/0/name', 'Test Rack')
	->json_schema_is("Racks");

$t->post_ok('/room', json => {
	wat => 'wat'
})->status_is(400);

$t->post_ok('/room', json => {
	datacenter => $dc_id,
	az => 'sungo-test-1',
})->status_is(303);

$t->get_ok($t->tx->res->headers->location)->status_is(200);
my $idr = $t->tx->res->json->{id};

$t->post_ok("/room/$idr", json => {
	vendor_name => 'sungo'
})->status_is(303);

$t->get_ok($t->tx->res->headers->location)->status_is(200)
	->json_is('/vendor_name', 'sungo');

$t->delete_ok("/room/$idr")->status_is(204);
$t->get_ok("/room/$idr")->status_is(404);

done_testing();
