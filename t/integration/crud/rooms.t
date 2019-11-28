use Mojo::Base -strict;
use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;
use Conch::UUID 'create_uuid_str';

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
my $rooms = $t->tx->res->json;
my $room = $rooms->[0];

my $datacenter = $t->load_fixture('datacenter_0');

$t->get_ok($_)
    ->status_is(200)
    ->json_schema_is('DatacenterRoomDetailed')
    ->json_is($room)
    foreach
        '/room/'.$room->{id},
        '/room/'.$room->{alias};

$t->get_ok('/room/'.$room->{id}.'/racks')
    ->status_is(200)
    ->json_schema_is('Racks')
    ->json_cmp_deeply([ superhashof({ name => 'rack.0a' }) ]);
my $rack = $t->tx->res->json->[0];

$t->get_ok('/room/'.$room->{alias}.'/racks')
    ->status_is(200)
    ->json_schema_is('Racks')
    ->json_is([ $rack ]);

$t->get_ok($_)
    ->status_is(200)
    ->json_schema_is('Rack')
    ->json_is($rack)
    foreach
        '/room/'.$room->{id}.'/rack/'.$rack->{id},
        '/room/'.$room->{id}.'/rack/rack.0a',
        '/room/'.$room->{alias}.'/rack/'.$rack->{id},
        '/room/'.$room->{alias}.'/rack/rack.0a';

my $build_user = $t->generate_fixtures('user_account', { name => 'build_user' });
my $build = $t->generate_fixtures('build');
$build->create_related('user_build_roles', { user_id => $build_user->id, role => 'admin' });

my $t2 = Test::Conch->new(pg => $t->pg);
$t2->authenticate(email => $build_user->email);

$t2->get_ok($_)
    ->status_is(403)
    foreach
        '/room',
        '/room/'.$room->{id},
        '/room/'.$room->{alias},
        '/room/'.$room->{id}.'/racks',
        '/room/'.$room->{alias}.'/racks',
        '/room/'.$room->{id}.'/rack/'.$rack->{id},
        '/room/'.$room->{id}.'/rack/rack.0a',
        '/room/'.$room->{alias}.'/rack/'.$rack->{id},
        '/room/'.$room->{alias}.'/rack/rack.0a';

$t->app->db_racks->search({ id => $rack->{id} })->update({ build_id => $build->id });
$rack->{build_id} = $build->id;

$t2->get_ok('/room')
    ->status_is(403);

$t2->get_ok($_)
    ->status_is(200)
    ->json_schema_is('DatacenterRoomDetailed')
    ->json_is($room)
    foreach
        '/room/'.$room->{id},
        '/room/'.$room->{alias};

$t2->get_ok($_)
    ->status_is(200)
    ->json_schema_is('Racks')
    ->json_is([ $rack ])
    foreach
        '/room/'.$room->{id}.'/racks',
        '/room/'.$room->{alias}.'/racks';

$t2->get_ok($_)
    ->status_is(200)
    ->json_schema_is('Rack')
    ->json_is($rack)
    foreach
        '/room/'.$room->{id}.'/rack/'.$rack->{id},
        '/room/'.$room->{id}.'/rack/rack.0a',
        '/room/'.$room->{alias}.'/rack/'.$rack->{id},
        '/room/'.$room->{alias}.'/rack/rack.0a';

$t->app->db_racks->create({
    datacenter_room_id => $room->{id},
    name => 'rack2',
    rack_role_id => $rack->{rack_role_id},
});

$t->get_ok('/room/'.$room->{id}.'/rack/rack2')
    ->status_is(200)
    ->json_schema_is('Rack')
    ->json_cmp_deeply(superhashof({ name => 'rack2' }));
my $rack2 = $t->tx->res->json;

$t->get_ok('/room/'.$room->{id}.'/racks')
    ->status_is(200)
    ->json_schema_is('Racks')
    ->json_is([ $rack, $rack2 ]);

$t2->get_ok($_)
    ->status_is(403)
    foreach
        '/room/'.$room->{id}.'/rack/'.$rack2->{id},
        '/room/'.$room->{id}.'/rack/rack2',
        '/room/'.$room->{alias}.'/rack/'.$rack2->{id},
        '/room/'.$room->{alias}.'/rack/rack2';

$t2->get_ok($_)
    ->status_is(200)
    ->json_schema_is('Racks')
    ->json_is([ $rack ])
    foreach
        '/room/'.$room->{id}.'/racks',
        '/room/'.$room->{alias}.'/racks';

$t->post_ok('/room', json => { wat => 'wat' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [ { path => '/', message => re(qr/properties not allowed/i) } ]);

$t->post_ok('/room', json => { datacenter_id => create_uuid_str, az => 'sungo-test-1', alias => 'me'})
    ->status_is(409)
    ->json_is({ error => 'Datacenter does not exist' });

$t2->post_ok('/room', json => { datacenter_id => $datacenter->id })
    ->status_is(403);

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

$t->post_ok('/room', json => { datacenter_id => $datacenter->id, az => 'sungo-test-1', alias => 'me' })
    ->status_is(409)
    ->json_is({ error => 'a room already exists with that alias' });

$t->post_ok("/room/$idr", json => { datacenter_id => create_uuid_str })
    ->status_is(409)
    ->json_is({ error => 'Datacenter does not exist' });

$t->post_ok("/room/$idr", json => { alias => $room->{alias} })
    ->status_is(409)
    ->json_is({ error => 'a room already exists with that alias' });

$t2->post_ok("/room/$idr", json => { vendor_name => 'sungo' })
    ->status_is(403);

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

$t->delete_ok('/room/'.$room->{id})
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'cannot delete a datacenter_room when a rack is referencing it' });

$t2->delete_ok("/room/$idr")
    ->status_is(403);

$t->delete_ok("/room/$idr")
    ->status_is(204);

$t->get_ok("/room/$idr")
    ->status_is(404)
    ->log_debug_is('Could not find datacenter room '.$idr);

done_testing;
