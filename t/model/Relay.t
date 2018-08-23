use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB qw(mk_tmp_db);

use_ok("Conch::Model::Device");
use_ok("Conch::Model::Relay");

use Data::UUID;
use Conch::Pg;

my $pgtmp = mk_tmp_db();
$pgtmp or die;
my $schema = Test::ConchTmpDB->schema($pgtmp);

my $pg    = Conch::Pg->new( $pgtmp->uri );
my $uuid = Data::UUID->new;

my $hardware_vendor_id = $pg->db->insert(
	'hardware_vendor',
	{ name      => 'test vendor' },
	{ returning => ['id'] }
)->hash->{id};
my $hardware_product_id = $pg->db->insert(
	'hardware_product',
	{
		name   => 'test hw product',
		alias  => 'alias',
		hardware_vendor_id => $hardware_vendor_id
	},
	{ returning => ['id'] }
)->hash->{id};

new_ok('Conch::Model::Relay');
my $relay_model = new_ok("Conch::Model::Relay");

my $relay_serial = 'deadbeef';
subtest "registering relay" => sub {
	is( $relay_model->lookup($relay_serial), undef, "Relay does not yet exist" );
	ok( $relay_model->register( $relay_serial, 'v1', '127.0.0.1', 22, 'test' ) );

	my $new_relay = $relay_model->lookup($relay_serial);

	is( $new_relay->id, $relay_serial, "New relay registered" );
	is( $new_relay->version, 'v1', "Relay version registered" );
	is( $new_relay->ipaddr, '127.0.0.1', "Relay IP registered" );
	is( $new_relay->ssh_port, 22, "Relay SSH port registered" );
	is( $new_relay->alias, 'test', "Relay alias registered" );

	ok( $relay_model->register( $relay_serial, 'v2', '127.0.0.2', 42, 'test2' ) );

	my $updated_relay = $relay_model->lookup($relay_serial);
	is( $updated_relay->id, $relay_serial, "New relay registered" );
	is( $updated_relay->version, 'v2', "Relay version registered" );
	is( $updated_relay->ipaddr, '127.0.0.2', "Relay IP registered" );
	is( $updated_relay->ssh_port, 42, "Relay SSH port registered" );
	is( $updated_relay->alias, 'test2', "Relay alias registered" );

	ok( $new_relay->created eq $updated_relay->created, "Relay created timestamp unchanged" );
	ok( $new_relay->updated ne $updated_relay->updated, "Relay updated timestamp changed" );
};

subtest "connect device relay" => sub {
	my $device_model = new_ok( "Conch::Model::Device");

	my $device_id =
		Conch::Model::Device->create( 'coffee', $hardware_product_id )->id;

	ok( $relay_model->connect_device_relay( $device_id, $relay_serial ) );
	ok( !$relay_model->connect_device_relay( $device_id, 'bad_serial' ) );
};

subtest "connect user relay" => sub {

	my $user = $schema->resultset('UserAccount')->create({
		name => 'foo',
		email => 'foo@bar.com',
		password => 'password',
	});
	my $user_id = $user->id;
	ok( $relay_model->connect_user_relay( $user_id, $relay_serial ) );
	ok( !$relay_model->connect_user_relay( $user_id, 'bad_serial' ) );
};

subtest "list" => sub {
	my $relays = $relay_model->list();
	is( scalar @$relays, 1,          "Relay count" );
	is( $relays->[0]->id, "deadbeef", "ID checks out" );
	isa_ok( $relays->[0]->created, 'Conch::Time' );
	isa_ok( $relays->[0]->updated, 'Conch::Time' );
};

done_testing();
