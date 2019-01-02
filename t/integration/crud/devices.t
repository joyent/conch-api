use v5.26;
use warnings;

use Test::More;
use Test::Warnings;
use Path::Tiny;
use Test::Conch;

my $t = Test::Conch->new;
$t->load_fixture('conch_user_global_workspace', '00-hardware', '01-hardware-profiles');
$t->load_validation_plans([{
    name        => 'Conch v1 Legacy Plan: Server',
    description => 'Test Plan',
    validations => [ 'Conch::Validation::DeviceProductName' ],
}]);

$t->authenticate;

subtest 'Set up a test device' => sub {

    $t->post_ok(
        '/relay/deadbeef/register',
        json => {
            serial   => 'deadbeef',
            version  => '0.0.1',
            ipaddr   => '127.0.0.1',
            ssh_port => '22',
            alias    => 'test relay',
        }
    )->status_is(204)->content_is('');

    my $report = path('t/integration/resource/passing-device-report.json')->slurp_utf8;
    $t->post_ok('/device/TEST', { 'Content-Type' => 'application/json' }, $report)->status_is(200)
        ->json_schema_is( 'ValidationState' );
};

subtest 'Device interfaces' => sub {
    $t->get_ok('/device/TEST/interface')
        ->status_is(200)
        ->json_schema_is('DeviceNics');

    $t->get_ok('/device/TEST/interface/ipmi1')
        ->status_is(200)
        ->json_schema_is('DeviceNic');

    $t->get_ok('/device/TEST/interface/ipmi1/mac')
        ->status_is(200)
        ->json_is({ mac => '18:66:da:78:d9:b3' });

    $t->get_ok('/device/TEST/interface/ipmi1/ipaddr')
        ->status_is(200)
        ->json_is({ ipaddr => '10.72.160.146' });
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
