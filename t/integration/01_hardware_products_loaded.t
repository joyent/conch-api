use Mojo::Base -strict;
use Test::More;
use Data::UUID;
use IO::All;
use Test::Warnings;
use Test::Conch;

use Data::Printer;


my $uuid = Data::UUID->new;
my $t = Test::Conch->new;

$t->schema->storage->dbh_do(sub {
	my ($storage, $dbh, @args) = @_;

	my @test_sql_files = qw( 00-hardware.sql );
	for my $file ( map { io->file("sql/test/$_") } @test_sql_files ) {
		$dbh->do( $file->all ) or BAIL_OUT("Test SQL load failed");
	}
});


$t->get_ok("/ping")->status_is(200)->json_is( '/status' => 'ok' );
$t->get_ok("/version")->status_is(200);

$t->post_ok(
	"/login" => json => {
		user     => 'conch',
		password => 'conch'
	}
)->status_is(200);
BAIL_OUT("Login failed") if $t->tx->res->code != 200;

isa_ok( $t->tx->res->cookie('conch'), 'Mojo::Cookie::Response' );

$t->get_ok('/workspace')->status_is(200)->json_is( '/0/name', 'GLOBAL' );

my $id = $t->tx->res->json->[0]{id};
BAIL_OUT("No workspace ID") unless $id;

subtest 'Register relay' => sub {
	$t->post_ok(
		'/relay/deadbeef/register',
		json => {
			serial   => 'deadbeef',
			version  => '0.0.1',
			idaddr   => '127.0.0.1',
			ssh_port => '22',
			alias    => 'test relay'
		}
	)->status_is(204);
};

subtest 'Relay List' => sub {
	$t->get_ok('/relay')->status_is(200);
	$t->json_is('/0/id' => 'deadbeef');
};

subtest 'Device Report' => sub {
	my $report =
		io->file('t/integration/resource/passing-device-report.json')->slurp;
	$t->post_ok( '/device/TEST', { 'Content-Type' => 'application/json' }, $report )
		->status_is(409)
		->json_is('/error', 'Hardware product does not contain a profile');
};

subtest 'Hardware Product' => sub {
	$t->get_ok("/hardware_product")->status_is(200)
		->json_is( '', [],
		'No hardware products because hardware product profiles are missing' );
};

$t->get_ok("/dc")->status_is(200)->json_is('', []);
$t->get_ok("/room")->status_is(200)->json_is('', []);
$t->get_ok("/rack_role")->status_is(200)->json_is('', []);
$t->get_ok("/rack")->status_is(200)->json_is('', []);
$t->get_ok("/layout")->status_is(200)->json_is('', []);

done_testing();
