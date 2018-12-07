use Mojo::Base -strict;
use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;

my $t = Test::Conch->new;
$t->load_fixture_set('workspace_room_rack_layout', 0);

$t->post_ok(
    '/login' => json => {
        user     => 'conch@conch.joyent.us',
        password => 'conch',
    }
)->status_is(200);
BAIL_OUT('Login failed') if $t->tx->res->code != 200;

$t->get_ok('/room')
    ->status_is(200)
    ->json_schema_is('DatacenterRoomsDetailed')
    ->json_cmp_deeply([
        superhashof({ az => 'room-0a', alias => 'room 0a' }),
    ]);

my $datacenter = $t->load_fixture('datacenter_0');
my $room = $t->load_fixture('datacenter_room_0a');

$t->get_ok('/room/'.$room->id)
    ->status_is(200)
    ->json_schema_is('DatacenterRoomDetailed')
    ->json_cmp_deeply(superhashof({ az => 'room-0a', alias => 'room 0a' }));

$t->get_ok('/room/'.$room->id.'/racks')
    ->status_is(200)
    ->json_schema_is('Racks')
    ->json_cmp_deeply([ superhashof({ name => 'rack 0a' }) ]);

$t->post_ok('/room', json => { wat => 'wat' })
    ->status_is(400)
    ->json_schema_is('Error');

$t->post_ok('/room', json => { datacenter => $datacenter->id, az => 'sungo-test-1' })
    ->status_is(303);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('DatacenterRoomDetailed')
    ->json_cmp_deeply(superhashof({ az => 'sungo-test-1', alias => undef }));
my $idr = $t->tx->res->json->{id};

$t->post_ok("/room/$idr", json => { vendor_name => 'sungo' })
    ->status_is(303);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('DatacenterRoomDetailed')
    ->json_cmp_deeply(superhashof({ az => 'sungo-test-1', alias => undef }));

$t->delete_ok("/room/$idr")
    ->status_is(204);

$t->get_ok("/room/$idr")
    ->status_is(404);

done_testing;
