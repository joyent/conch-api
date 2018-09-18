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

my $fake_id = $uuid->create_str();

$t->get_ok("/room")->status_is(200);
my $room_id = $t->tx->res->json->[0]->{id};

$t->get_ok('/rack_role')->status_is(200);
my $role_id = $t->tx->res->json->[0]{id};


$t->get_ok('/rack')->status_is(200)->json_schema_is('Racks');

my $id = $t->tx->res->json->[0]{id};
my $name = $t->tx->res->json->[0]{name};

$t->get_ok("/rack/$id")->status_is(200)->json_schema_is('Rack');
$t->get_ok("/rack/name=$name")->status_is(200)->json_schema_is('Rack');

$t->post_ok("/rack", json => {
	wat => 'wat'
})->status_is(400);

$t->post_ok("/rack", json => {
	name => 'r4ck',
	datacenter_room_id => $fake_id,
	role => $role_id,
})->status_is(400)->json_schema_is('Error');

$t->post_ok("/rack", json => {
	name => 'r4ck',
	datacenter_room_id => $room_id,
	role => $fake_id,
})->status_is(400)->json_schema_is('Error');


$t->post_ok("/rack", json => {
	name => 'r4ck',
	datacenter_room_id => $room_id,
	role => $role_id,
})->status_is(303);


$t->get_ok($t->tx->res->headers->location)->status_is(200)
	->json_schema_is('Rack');
my $idr = $t->tx->res->json->{id};

$t->post_ok("/rack/$idr", json => {
	name => 'rack',
	serial_number => 'abc',
	asset_tag => 'deadbeef',
})->status_is(303);

$t->get_ok($t->tx->res->headers->location)->status_is(200)
	->json_is('/name' => 'rack')
	->json_schema_is('Rack');

$t->post_ok("/rack", json => {
	datacenter_room_id => $fake_id
})->status_is(400)->json_schema_is('Error');

$t->post_ok("/rack", json => {
	role => $fake_id
})->status_is(400)->json_schema_is('Error');

$t->delete_ok("/rack/$idr")->status_is(204);
$t->get_ok("/rack/$idr")->status_is(404);


done_testing();
