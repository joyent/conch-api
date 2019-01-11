use Mojo::Base -strict;
use Test::More;
use Data::UUID;
use Path::Tiny;
use Test::Warnings;
use Test::Conch;

my $uuid = Data::UUID->new;

my $t = Test::Conch->new;
$t->load_fixture('conch_user_global_workspace', '00-hardware');

$t->authenticate;

isa_ok( $t->tx->res->cookie('conch'), 'Mojo::Cookie::Response' );

$t->get_ok('/workspace')->status_is(200)->json_is( '/0/name', 'GLOBAL' );

my $id = $t->tx->res->json->[0]{id};
BAIL_OUT("No workspace ID") unless $id;

subtest 'Device Report' => sub {
	my $report =
		path('t/integration/resource/passing-device-report.json')->slurp_utf8;
	$t->post_ok( '/device/TEST', { 'Content-Type' => 'application/json' }, $report )
		->status_is(409)
		->json_is({ error => 'Hardware product does not contain a profile' });
};

$t->get_ok("/dc")->status_is(200)->json_is('', []);
$t->get_ok("/room")->status_is(200)->json_is('', []);
$t->get_ok("/rack_role")->status_is(200)->json_is('', []);
$t->get_ok("/rack")->status_is(200)->json_is('', []);
$t->get_ok("/layout")->status_is(200)->json_is('', []);

done_testing();
