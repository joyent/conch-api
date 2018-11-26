use Mojo::Base -strict;
use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;

my $t = Test::Conch->new;
$t->load_fixture('conch_user_global_workspace');

$t->authenticate;

$t->get_ok('/rack_role')
    ->status_is(200)
    ->json_schema_is('RackRoles')
    ->json_is([]);

$t->load_fixture_set('workspace_room_rack_layout', 0);
my $role = $t->load_fixture('rack_role_42u');

$t->get_ok('/rack_role')
    ->status_is(200)
    ->json_schema_is('RackRoles')
    ->json_cmp_deeply([
        superhashof({ name => 'rack_role 42U', rack_size => 42 }),
    ]);

$t->get_ok('/rack_role/'.$role->id)
    ->status_is(200)
    ->json_schema_is('RackRole')
    ->json_cmp_deeply(superhashof({ name => 'rack_role 42U', rack_size => 42 }));

$t->get_ok('/rack_role/name=rack_role 42U')
    ->status_is(200)
    ->json_schema_is('RackRole')
    ->json_cmp_deeply(superhashof({ name => 'rack_role 42U', rack_size => 42 }));

$t->post_ok('/rack_role', json => { wat => 'wat' })
    ->status_is(400)
    ->json_cmp_deeply({ error => re(qr/Properties not allowed/) });

$t->post_ok('/rack_role', json => { name => 'foo/bar' })
    ->status_is(400)
    ->json_cmp_deeply({ error => re(qr/name: .*does not match/) });

$t->post_ok('/rack_role', json => { name => 'foo.bar' })
    ->status_is(400)
    ->json_cmp_deeply({ error => re(qr/name: .*does not match/) });

$t->post_ok('/rack_role', json => { name => 'r0le', rack_size => 2 })
    ->status_is(303);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('RackRole')
    ->json_cmp_deeply(superhashof({ name => 'r0le', rack_size => 2 }));
my $idr = $t->tx->res->json->{id};

$t->post_ok('/rack_role', json => { name => 'r0le', rack_size => 10 })
    ->status_is(400)
    ->json_schema_is('Error')
    ->json_is({ error => 'name is already taken' });

$t->post_ok("/rack_role/$idr", json => { name => 'role' })
    ->status_is(303);

$t->get_ok("/rack_role/$idr")
    ->status_is(200)
    ->json_schema_is('RackRole')
    ->json_cmp_deeply(superhashof({ name => 'role', rack_size => 2 }));

$t->post_ok("/rack_role/$idr", json => { rack_size => 10 })
    ->status_is(303);

$t->get_ok("/rack_role/$idr")
    ->status_is(200)
    ->json_schema_is('RackRole')
    ->json_cmp_deeply(superhashof({ name => 'role', rack_size => 10 }));

$t->post_ok('/rack_role/'.$role->id, json => { rack_size => 13 })
    ->status_is(400)
    ->json_schema_is('Error')
    ->json_is({ error => 'cannot resize rack_role: found an assigned rack layout that extends beyond the new rack_size' });

$t->post_ok('/rack_role/'.$role->id, json => { rack_size => 14 })
    ->status_is(303);

$t->get_ok('/rack_role/'.$role->id)
    ->status_is(200)
    ->json_schema_is('RackRole')
    ->json_cmp_deeply(superhashof({ name => 'rack_role 42U', rack_size => 14 }));

$t->get_ok('/rack_role')
    ->status_is(200)
    ->json_schema_is('RackRoles')
    ->json_cmp_deeply(bag(
        superhashof({ name => 'rack_role 42U', rack_size => 14 }),
        superhashof({ name => 'role', rack_size => 10 }),
    ));

$t->delete_ok('/rack_role/'.$role->id)
    ->status_is(400)
    ->json_schema_is('Error')
    ->json_is({ error => 'cannot delete a rack_role when a rack is referencing it' });

$t->delete_ok("/rack_role/$idr")
    ->status_is(204);

$t->get_ok("/rack_role/$idr")
    ->status_is(404);

$t->get_ok('/rack_role')
    ->status_is(200)
    ->json_schema_is('RackRoles')
    ->json_cmp_deeply([
        superhashof({ name => 'rack_role 42U', rack_size => 14 }),
    ]);

done_testing();
# vim: set ts=4 sts=4 sw=4 et :
