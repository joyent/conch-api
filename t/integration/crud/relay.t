use v5.26;
use strict;
use warnings;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;
use Conch::UUID 'create_uuid_str';

my $t = Test::Conch->new;
my $super_user = $t->load_fixture('super_user');
my $null_user = $t->generate_fixtures('user_account');
my $hardware_product = $t->load_fixture('hardware_product_compute');

$t->authenticate(email => $null_user->email);

my $t_super = Test::Conch->new(pg => $t->pg);
$t_super->authenticate(email => $super_user->email);

$t->post_ok('/relay/relay'.$_.'/register',
        json => {
            serial => 'relay'.$_,
            name => 'relay_number_'.$_,
            version => 'v1.'.$_,
            ipaddr => '192.168.'.$_.'.2',
            ssh_port => 123,
        })
    ->status_is(201)
    ->location_like(qr!^/relay/${\Conch::UUID::UUID_FORMAT}$!)
foreach (0..1);

my $relay0 = $t->app->db_relays->find({ serial_number => 'relay0' });
my $relay1 = $t->app->db_relays->find({ serial_number => 'relay1' });

cmp_deeply(
    $relay0,
    methods(
        serial_number => 'relay0',
        user_id => $null_user->id,
        last_seen => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
    ),
    'relay registration updates fields',
);

my $rs = $t->app->db_relays->search({ serial_number => 'relay0' })->rows(1);

my ($relay_data) = $rs->hri->all;

$t->post_ok('/relay/relay0/register', json => { serial => 'relay0' })
    ->status_is(204)
    ->location_is('/relay/'.$relay0->id);

my ($new_relay_data) = $rs->hri->all;

isnt($new_relay_data->{last_seen}, $relay_data->{last_seen}, 'relay.last_seen has been updated');
is($new_relay_data->{updated}, $relay_data->{updated}, 'relay update timestamp did not change');

$relay0->last_seen(Conch::Time->from_string($new_relay_data->{last_seen}, lenient => 1));

$t->get_ok('/relay/'.create_uuid_str())
    ->status_is(404)
    ->log_debug_like(qr/^Could not find relay ${\Conch::UUID::UUID_FORMAT}$/);

$t->get_ok('/relay/'.$relay0->id)
    ->status_is(200)
    ->json_schema_is('Relay')
    ->json_is({
        id => $relay0->id,
        serial_number => 'relay0',
        name => 'relay_number_0',
        version => 'v1.0',
        ipaddr => '192.168.0.2',
        ssh_port => 123,
        created => $relay0->created,
        updated => $relay0->updated,
        last_seen => $relay0->last_seen,
        user_id => $null_user->id,
    });

$t->get_ok('/relay/relay0')
    ->status_is(200)
    ->json_schema_is('Relay')
    ->json_is({
        id => $relay0->id,
        serial_number => 'relay0',
        name => 'relay_number_0',
        version => 'v1.0',
        ipaddr => '192.168.0.2',
        ssh_port => 123,
        created => $relay0->created,
        updated => $relay0->updated,
        last_seen => $relay0->last_seen,
        user_id => $null_user->id,
    });

$t->get_ok('/relay')
    ->status_is(403)
    ->log_debug_is('User must be system admin');

$t_super->get_ok('/relay')
    ->status_is(200)
    ->json_schema_is('Relays')
    ->json_cmp_deeply([
        map +{
            id => ($relay0, $relay1)[$_]->id,
            serial_number => 'relay'.$_,
            name => 'relay_number_'.$_,
            version => 'v1.'.$_,
            ipaddr => '192.168.'.$_.'.2',
            ssh_port => 123,
            created => str(($relay0, $relay1)[$_]->created),
            updated => str(($relay0, $relay1)[$_]->updated),
            last_seen => str(($relay0, $relay1)[$_]->last_seen),
            user_id => $null_user->id,
        }, (0..1)
    ]);

{
    my $other_user = $t->generate_fixtures('user_account');
    my $t2 = Test::Conch->new(pg => $t->pg);
    $t2->authenticate(email => $other_user->email);

    $t2->get_ok('/relay')
        ->status_is(403)
        ->log_debug_is('User must be system admin');

    $t2->get_ok('/relay/relay0')
        ->status_is(403)
        ->log_debug_is('User cannot access unregistered relay relay0');

    $t2->post_ok('/relay/relay0/register', json => { serial => 'relay0' })
        ->status_is(204)
        ->location_is('/relay/'.$relay0->id);

    $t2->get_ok('/relay/relay0')
        ->status_is(200)
        ->json_schema_is('Relay')
        ->json_cmp_deeply({
            (map +($_ => str($relay0->$_)), qw(id serial_number name version ipaddr ssh_port created)),
            last_seen => ignore,
            updated => ignore,
            user_id => $other_user->id,
        });
    isnt($t2->tx->res->json->{updated}, $relay0->updated, 'updated timestamp has changed');
}

$relay0->update({
    last_seen => '1999-01-01',
});

$t->post_ok('/relay/relay0/register',
        json => {
            serial => 'relay0',
            version => 'v2.0',
        })
    ->status_is(204)
    ->location_is('/relay/'.$relay0->id);

$relay0->discard_changes;    # reload from db

$t_super->get_ok('/relay')
    ->status_is(200)
    ->json_schema_is('Relays')
    ->json_cmp_deeply('', superbagof(superhashof({
            serial_number => 'relay0',
            version => 'v2.0',
        })), 'version was updated');

my $y2000 = Conch::Time->new(year => 2000);
cmp_ok($relay0->last_seen, '>', $y2000, 'relay last_seen was updated');

my $device_num = 0;
my @devices = map $t->app->db_devices->create({
    serial_number => 'DEVICE'.$device_num++,
    hardware_product_id => $hardware_product->id,
    health  => 'unknown',
    device_relay_connections => [{
        relay_id => $relay0->id,
        first_seen => '2001-01-01',
        last_seen => '2018-01-01',
    }],
}), 0..1;

subtest delete => sub {
    $t->delete_ok('/relay/'.$relay0->id)
        ->status_is(403)
        ->log_debug_is('User must be system admin');

    $t_super->delete_ok('/relay/'.$relay0->id)
        ->status_is(204)
        ->log_debug_is('Deactivated relay '.$relay0->id.', removing 2 associated device connections');

    $t_super->get_ok('/relay/'.$relay0->id)
        ->status_is(410);

    $t_super->delete_ok('/relay/'.$relay0->id)
        ->status_is(410);
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
