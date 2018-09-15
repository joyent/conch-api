use Mojo::Base -strict;
use Test::More;
use Data::UUID;
use Path::Tiny;
use Test::Warnings;
use Test::Conch;

use Data::Printer;

my $uuid = Data::UUID->new;

my $t = Test::Conch->new;

Test::Conch->load_validation_plans(
	[{
		name        => 'Conch v1 Legacy Plan: Server',
		description => 'Test Plan',
		validations => [ { name => 'product_name', version => 1 } ]
	}],
	$t->app->log,
);

$t->load_test_sql(qw( 00-hardware.sql 01-hardware-profiles.sql ));

$t->get_ok("/ping")->status_is(200)->json_is( '/status' => 'ok' );
$t->get_ok("/version")->status_is(200);

$t->post_ok(
	"/login" => json => {
		user     => 'conch@conch.joyent.us',
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
		path('t/integration/resource/passing-device-report.json')->slurp_utf8;
	$t->post_ok( '/device/TEST', { 'Content-Type' => 'application/json' }, $report )->status_is( 200,
'Device reports process despite hardware profiles not having a zpool profile'
	)->json_is( '/status', 'pass' );
};

subtest 'Hardware Product' => sub {
	$t->get_ok("/hardware_product")->status_is(200);
	my @hardware_products = $t->tx->res->json->@*;
	is( scalar @hardware_products, 3 );
	my @hardware_product_names = sort map { $_->{name} } @hardware_products;
	is_deeply(
		\@hardware_product_names,
		[
			'2-ssds-1-cpu', '65-ssds-2-cpu',
			'Switch'
		]
	);
	for my $hardware_product (@hardware_products) {
		ok(
			!defined( $hardware_product->{profile}->{zpool} ),
			'No product has zpool profile defined'
		);
		$t->get_ok( "/hardware_product/" . $hardware_product->{id} )
			->status_is(200)->json_is( '', $hardware_product );
	}
};

subtest 'Hardware Vendors' => sub {
	$t->get_ok('/hardware_vendor')->status_is(200)
		->json_schema_is('HardwareVendors');

	my $all_vendors = $t->tx->res->json;

	$t->get_ok("/hardware_vendor/$all_vendors->[0]{name}")->status_is(200)
		->json_schema_is('HardwareVendor')
		->json_is($all_vendors->[0]);

	$t->ua->max_redirects(0);
	$t->post_ok('/hardware_vendor/MyNewVendor')
		->status_is(303)
		->location_is('/hardware_vendor/MyNewVendor');

	$t->get_ok('/hardware_vendor/MyNewVendor')->status_is(200)
		->json_schema_is('HardwareVendor')
		->json_is('/name', 'MyNewVendor');

	$t->get_ok('/hardware_vendor')->status_is(200);
	is(scalar($t->tx->res->json->@*), scalar($all_vendors->@*) + 1, 'new vendor in returned list');

	$t->delete_ok('/hardware_vendor/MyNewVendor')->status_is(204);
	$t->delete_ok('/hardware_vendor/MyNewVendor')->status_is(404);

	$t->get_ok('/hardware_vendor')->status_is(200)
		->json_schema_is('HardwareVendors')
		->json_is('', $all_vendors, 'deleted vendor is not in returned list');

	$t->get_ok('/hardware_vendor/MyNewVendor')->status_is(404);
};

done_testing();
