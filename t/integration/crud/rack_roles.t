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

$t->get_ok('/rack_role')
    ->status_is(200)
    ->json_schema_is('RackRoles');

my $id = $t->tx->res->json->[0]{id};
my $name = $t->tx->res->json->[0]{name};

$t->get_ok("/rack_role/$id")
    ->status_is(200)
    ->json_schema_is('RackRole');

$t->get_ok("/rack_role/name=$name")
    ->status_is(200)
    ->json_schema_is('RackRole');

$t->post_ok('/rack_role', json => { wat => 'wat' })
    ->status_is(400);

$t->post_ok('/rack_role', json => { name => 'r0le', rack_size => 2 })
    ->status_is(303);


$t->get_ok($t->tx->res->headers->location)->status_is(200)
    ->json_schema_is('RackRole');
my $idr = $t->tx->res->json->{id};

$t->post_ok('/rack_role', json => { name => 'r0le', rack_size => 2 })
    ->status_is(400)
    ->json_schema_is('Error');

$t->post_ok("/rack_role/$idr", json => { name => 'role' })
    ->status_is(303);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_is('/name' => 'role')
    ->json_schema_is('RackRole');

$t->delete_ok("/rack_role/$idr")
    ->status_is(204);
$t->get_ok("/rack_role/$idr")
    ->status_is(404);

done_testing();
# vim: set ts=4 sts=4 sw=4 et :
