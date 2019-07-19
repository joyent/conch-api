use Mojo::Base -strict;
use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;

my $t = Test::Conch->new;
$t->load_fixture('super_user');

$t->authenticate;

$t->get_ok('/dc')
    ->status_is(200)
    ->json_schema_is('Datacenters')
    ->json_is([]);

$t->load_fixture_set('workspace_room_rack_layout', 0);

$t->get_ok('/dc')
    ->status_is(200)
    ->json_schema_is('Datacenters')
    ->json_cmp_deeply([
        superhashof({ vendor => 'Acme Corp', region => 'region_0', location => 'Earth' }),
    ]);

my $datacenter = $t->load_fixture('datacenter_0');

$t->get_ok('/dc/'.$datacenter->id)
    ->status_is(200)
    ->json_schema_is('Datacenter')
    ->json_cmp_deeply(
        superhashof({ vendor => 'Acme Corp', region => 'region_0', location => 'Earth' }),
    );

$t->get_ok('/dc/'.$datacenter->id.'/rooms')
    ->status_is(200)
    ->json_schema_is('DatacenterRoomsDetailed')
    ->json_cmp_deeply([
        superhashof({ az => 'room-0a', alias => 'room 0a' }),
    ]);


$t->post_ok('/dc', json => { wat => 'wat' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/', message => re(qr/properties not allowed/i) } ]);

$t->post_ok('/dc', json => { vendor => 'vend0r', region => 'regi0n', location => 'locati0n' })
    ->status_is(201)
    ->location_like(qr!^/dc/${\Conch::UUID::UUID_FORMAT}!);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('Datacenter')
    ->json_cmp_deeply(
        superhashof({ vendor => 'vend0r', region => 'regi0n', location => 'locati0n' }),
    );
my $idd = $t->tx->res->json->{id};

$t->post_ok('/dc', json => { vendor => 'vend0r', region => 'regi0n', location => 'locati0n' })
    ->status_is(204)
    ->location_is('/dc/'.$idd);

$t->post_ok('/dc', json => { vendor => 'vend0r', region => 'regi0n', location => 'locati0n', vendor_name => 'hi' })
    ->status_is(409)
    ->json_is({ error => 'a datacenter already exists with that vendor-region-location' });

$t->post_ok("/dc/$idd", json => { vendor => 'vendor' })
    ->status_is(303);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('Datacenter')
    ->json_cmp_deeply(
        superhashof({ vendor => 'vendor', region => 'regi0n', location => 'locati0n' }),
    );

$t->delete_ok('/dc/'.$datacenter->id)
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'cannot delete a datacenter when a datacenter_room is referencing it' });

$t->delete_ok("/dc/$idd")
    ->status_is(204);

$t->get_ok("/dc/$idd")
    ->status_is(404);

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
