use Mojo::Base -strict;
use Test::More;
use Test::Warnings;
use Data::UUID;
use Test::Deep;
use Test::Conch::Datacenter;

my $t = Test::Conch::Datacenter->new();

my $uuid = Data::UUID->new;

$t->post_ok(
	"/login" => json => {
		user     => 'conch@conch.joyent.us',
		password => 'conch'
	}
)->status_is(200);
BAIL_OUT("Login failed") if $t->tx->res->code != 200;

$t->get_ok('/db/hardware_product')
	->status_is(200)
	->json_schema_is('DBHardwareProducts');

my $products = $t->tx->res->json;

my $hw_id = $products->[0]{id};
my $vendor_id = $products->[0]{vendor};

$t->get_ok("/db/hardware_product/$hw_id")
	->status_is(200)
	->json_schema_is("DBHardwareProduct")
	->json_is('', $products->[0]);

$t->post_ok('/db/hardware_product', json => { wat => 'wat' })
	->status_is(400)
	->json_schema_is('Error');

$t->post_ok('/db/hardware_product', json => {
		name => 'sungo',
		vendor => $vendor_id,
		alias => 'sungo',
	})
	->status_is(303);

$t->get_ok($t->tx->res->headers->location)
	->status_is(200)
	->json_schema_is('DBHardwareProduct')
	->json_cmp_deeply('', {
		id => ignore,
		name => 'sungo',
		alias => 'sungo',
		prefix => undef,
		vendor => $vendor_id,
		created => ignore,
		updated => ignore,
		specification => undef,
		sku => undef,
		generation_name => undef,
		legacy_product_name => undef,
	});

my $new_product = $t->tx->res->json;
my $new_hw_id = $new_product->{id};

$t->get_ok('/hardware_product')
	->status_is(200)
	->json_schema_is('HardwareProducts')
	->json_cmp_deeply('',
		bag(map { superhashof(+{ $_->%{ qw(id name alias prefix) } }) } @$products),
		'new product is not included because it has no profile');

$t->post_ok('/db/hardware_product', json => {
		name => 'sungo',
		vendor => $vendor_id,
		alias => 'sungo',
	})
	->status_is(400)
	->json_schema_is('Error')
	->json_is('', { error => 'Unique constraint violated on \'name\'' });

$t->post_ok("/db/hardware_product/$new_hw_id", json => {
		id => $new_hw_id,
		name => 'sungo2',
	})
	->status_is(303);

$new_product->{name} = 'sungo2';
$new_product->{updated} = ignore;

$t->get_ok($t->tx->res->headers->location)
	->status_is(200)
	->json_schema_is('DBHardwareProduct')
	->json_cmp_deeply('', $new_product);

$t->get_ok('/db/hardware_product/name=sungo')
	->status_is(404);

$t->get_ok('/db/hardware_product/name=sungo2')
	->status_is(200)
	->json_schema_is('DBHardwareProduct')
	->json_cmp_deeply('', $new_product);


subtest 'delete a hardware product' => sub {

	$t->delete_ok("/db/hardware_product/$new_hw_id")->status_is(204);
	$t->get_ok("/db/hardware_product/$new_hw_id")->status_is(404);

	$t->get_ok('/hardware_product')
		->status_is(200)
		->json_schema_is('HardwareProducts');
};

done_testing();
