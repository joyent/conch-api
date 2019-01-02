use Mojo::Base -strict;
use Test::More;
use Test::Warnings;
use Test::Deep;
use Data::UUID;
use Test::Conch;

my $t = Test::Conch->new;
$t->load_fixture_set('workspace_room_rack_layout', 0);

my $uuid = Data::UUID->new;

$t->authenticate;

my $fake_id = $uuid->create_str();

my $rack = $t->load_fixture('datacenter_rack_0a');

$t->get_ok('/rack')
    ->status_is(200)
    ->json_schema_is('Racks')
    ->json_cmp_deeply([ superhashof({ name => 'rack 0a' }) ]);

$t->get_ok('/rack/'.$rack->id)
    ->status_is(200)
    ->json_schema_is('Rack')
    ->json_cmp_deeply(superhashof({ name => 'rack 0a' }));

$t->post_ok('/rack', json => { wat => 'wat' })
    ->status_is(400)
    ->json_schema_is('Error');

$t->post_ok('/rack', json => { name => 'r4ck', datacenter_room_id => $fake_id })
    ->status_is(400)
    ->json_schema_is('Error');

$t->post_ok('/rack', json => { name => 'r4ck', role => $fake_id })
    ->status_is(400)
    ->json_schema_is('Error');

$t->post_ok('/rack', json => {
        name => 'r4ck',
        datacenter_room_id => $fake_id,
        role => $rack->datacenter_rack_role_id,
    })
    ->status_is(400)
    ->json_schema_is('Error')
    ->json_is({ error => 'Room does not exist' });

$t->post_ok('/rack', json => {
        name => 'r4ck',
        datacenter_room_id => $rack->datacenter_room_id,
        role => $fake_id,
    })
    ->status_is(400)
    ->json_schema_is('Error')
    ->json_is({ error => 'Rack role does not exist' });

$t->post_ok('/rack', json => {
        name => 'r4ck',
        datacenter_room_id => $rack->datacenter_room_id,
        role => $rack->datacenter_rack_role_id,
    })
    ->status_is(303);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('Rack')
    ->json_cmp_deeply(superhashof({ name => 'r4ck' }));
my $idr = $t->tx->res->json->{id};

my $small_rack_role = $t->app->db_datacenter_rack_roles->create({ name => '10U', rack_size => 10 });

$t->post_ok('/rack/'.$rack->id, json => { role => $small_rack_role->id })
    ->status_is(400)
    ->json_schema_is('Error')
    ->json_is({ error => 'cannot resize rack: found an assigned rack layout that extends beyond the new rack_size' });

$t->post_ok("/rack/$idr", json => {
        name => 'rack',
        serial_number => 'abc',
        asset_tag => 'deadbeef',
    })
    ->status_is(303);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('Rack')
    ->json_cmp_deeply(superhashof({ name => 'rack', serial_number => 'abc', asset_tag => 'deadbeef' }));

$t->delete_ok('/rack/'.$rack->id)
    ->status_is(400)
    ->json_schema_is('Error')
    ->json_is({ error => 'cannot delete a datacenter_rack when a detacenter_rack_layout is referencing it' });

$t->delete_ok("/rack/$idr")
    ->status_is(204);

$t->get_ok("/rack/$idr")
    ->status_is(404);

done_testing();
# vim: set ts=4 sts=4 sw=4 et :
