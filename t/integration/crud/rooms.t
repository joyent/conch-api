use Mojo::Base -strict;
use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;

my $t = Test::Conch->new;
$t->load_fixture('super_user');

$t->authenticate;

$t->get_ok('/room')
    ->status_is(200)
    ->json_schema_is('DatacenterRoomsDetailed')
    ->json_is([]);

$t->load_fixture_set('workspace_room_rack_layout', 0);

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

$t->get_ok('/room/'.$room->alias)
    ->status_is(200)
    ->json_schema_is('DatacenterRoomDetailed')
    ->json_cmp_deeply(superhashof({ az => 'room-0a', alias => 'room 0a' }));

$t->get_ok('/room/'.$room->id.'/racks')
    ->status_is(200)
    ->json_schema_is('Racks')
    ->json_cmp_deeply([ superhashof({ name => 'rack.0a' }) ]);

$t->get_ok('/room/'.$room->alias.'/racks')
    ->status_is(200)
    ->json_schema_is('Racks')
    ->json_cmp_deeply([ superhashof({ name => 'rack.0a' }) ]);

$t->get_ok('/room/'.$room->alias.'/rack/rack.0a')
    ->status_is(200)
    ->json_schema_is('Rack')
    ->json_cmp_deeply(superhashof({ name => 'rack.0a' }));

$t->post_ok('/room', json => { wat => 'wat' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/', message => re(qr/properties not allowed/i) } ]);

$t->post_ok('/room', json => { datacenter_id => $datacenter->id, az => 'sungo-test-1', alias => 'me' })
    ->status_is(303);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('DatacenterRoomDetailed')
    ->json_cmp_deeply(superhashof({
        az => 'sungo-test-1',
        alias => 'me',
        vendor_name => undef,
    }));

my $idr = $t->tx->res->json->{id};

$t->post_ok("/room/$idr", json => { vendor_name => 'sungo', alias => 'you' })
    ->status_is(303);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('DatacenterRoomDetailed')
    ->json_cmp_deeply(superhashof({
        az => 'sungo-test-1',
        alias => 'you',
        vendor_name => 'sungo',
    }));

$t->delete_ok('/room/'.$room->id)
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'cannot delete a datacenter_room when a rack is referencing it' });

$t->delete_ok("/room/$idr")
    ->status_is(204);

$t->get_ok("/room/$idr")
    ->status_is(404)
    ->log_debug_is('Could not find datacenter room '.$idr);

done_testing;
