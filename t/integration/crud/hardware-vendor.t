use Mojo::Base -strict;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More;
use Test::Warnings;
use Conch::UUID 'create_uuid_str';
use Test::Deep;
use Test::Conch;

my $t = Test::Conch->new;
$t->load_fixture(qw(conch_user_global_workspace hardware_vendor_0));

$t->authenticate;

$t->get_ok('/hardware_vendor')
    ->status_is(200)
    ->json_schema_is('HardwareVendors');

my $vendors = $t->tx->res->json;

$t->get_ok('/hardware_vendor/'.create_uuid_str())
    ->status_is(404);

$t->get_ok('/hardware_vendor/foo')
    ->status_is(404);

$t->get_ok('/hardware_vendor/'.$vendors->[0]{id})
    ->status_is(200)
    ->json_schema_is('HardwareVendor')
    ->json_is($vendors->[0]);

$t->get_ok('/hardware_vendor/'.$vendors->[0]{name})
    ->status_is(200)
    ->json_schema_is('HardwareVendor')
    ->json_is($vendors->[0]);

$t->ua->max_redirects(0);
$t->post_ok('/hardware_vendor/MyNewVendor')
    ->status_is(303)
    ->location_is('/hardware_vendor/MyNewVendor');

$t->get_ok('/hardware_vendor/MyNewVendor')
    ->status_is(200)
    ->json_schema_is('HardwareVendor')
    ->json_cmp_deeply({
        name => 'MyNewVendor',
        id => ignore,
        created => ignore,
        updated => ignore,
    });

push @$vendors, $t->tx->res->json;

$t->get_ok('/hardware_vendor')
    ->status_is(200)
    ->json_schema_is('HardwareVendors')
    ->json_cmp_deeply(bag(@$vendors));

$t->delete_ok('/hardware_vendor/MyNewVendor')
    ->status_is(204);

$t->delete_ok('/hardware_vendor/MyNewVendor')
    ->status_is(404);

$t->get_ok('/hardware_vendor')
    ->status_is(200)
    ->json_schema_is('HardwareVendors')
    ->json_is('', [ $vendors->[0] ], 'deleted vendor is not in returned list');

$t->get_ok('/hardware_vendor/MyNewVendor')
    ->status_is(404);

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
