use Mojo::Base -strict;
use Test::More;
use Test::ConchTmpDB qw(mk_tmp_db);

use Try::Tiny;
use IO::All;

use_ok("Conch::Model::Device");

use Data::UUID;

use Conch::Pg;

my $pgtmp = mk_tmp_db();
$pgtmp or die;
my $schema = Test::ConchTmpDB->schema($pgtmp);

my $pg    = Conch::Pg->new($pgtmp->uri);

my $uuid = Data::UUID->new;

my ( $hw_vendor_id, $hw_product_id );

try {
	$hw_vendor_id = $pg->db->insert(
		'hardware_vendor',
		{ name      => 'test vendor' },
		{ returning => ['id'] }
	)->hash->{id};

	$hw_product_id = $pg->db->insert(
		'hardware_product',
		{
			name   => 'test hw product',
			alias  => 'alias',
			hardware_vendor_id => $hw_vendor_id
		},
		{ returning => ['id'] }
	)->hash->{id};
}
catch {
	BAIL_OUT("Setup failed: $_");
};

my $d;
my $device_serial = 'c0ff33';
subtest "Create new device" => sub {

	$d = Conch::Model::Device->create( $device_serial, $hw_product_id );

	isa_ok( $d, "Conch::Model::Device" );
	is( $d->id,    $device_serial, "New device ID matches expectations" );
	is( $d->state, "UNKNOWN",      "New device state matches expectations" );

	is( $d->hardware_product_id, $hw_product_id,
		"New device hardware product id matches expectations" );

	my $duplicate =
		Conch::Model::Device->create( $device_serial, $hw_product_id );
	is( $duplicate, undef, "Duplicate creation attempt fails" );
};

my $user;
subtest "Lookup" => sub {
	my $d2 = Conch::Model::Device->lookup( $d->id );
	isa_ok( $d2, "Conch::Model::Device" );
	is_deeply( $d2, $d, "Looked-up device matches expectations" );

	is(
		Conch::Model::Device->lookup( 'bad device id' ),
		undef, "Lookup for bad device fails",
	);

	$user = $schema->resultset('UserAccount')->create({
		email => 'foo@bar.com',
		name => 'foo',
		password => 'password',
	});
	is( Conch::Model::Device->lookup_for_user( $user->id, $d->id ),
		undef, "brand new user can't find a device" );

};

subtest "Device Modifiers" => sub {
	subtest "graduate" => sub {
		is( $d->graduated, undef, "graduated is not already set" );

		is( $d->graduate(), 1, "graduate affects 1 row" );
		ok( $d->graduated, "graduated is set on the object" );

		is( Conch::Model::Device->lookup( $d->id )->graduated,
			$d->graduated, "graduated is set in the db" );
	};

	subtest "triton_setup" => sub {
		is( $d->triton_setup, undef, "triton_setup is not already set" );

		is( $d->set_triton_setup(), 1, "set_triton_setup affects 1 row" );
		ok( $d->triton_setup, "triton_setup is set on the object" );

		is( Conch::Model::Device->lookup( $d->id )->triton_setup,
			$d->triton_setup, "triton_setup is set in the db" );
	};

	subtest "triton_uuid" => sub {
		my $d_uuid = lc( $uuid->create_str() );    # the db lowercases UUIDs
		is( $d->triton_uuid, undef, "triton_uuid is not already set" );

		is( $d->set_triton_uuid($d_uuid), 1, "set_triton_uuid affects 1 row" );
		is( $d->triton_uuid, $d_uuid,
			"triton_uuid is set appropriately on the object" );

		is( Conch::Model::Device->lookup( $d->id )->triton_uuid,
			$d_uuid, "triton_uuid is set appropriately in the db" );
	};

	subtest "latest_triton_reboot" => sub {
		is( $d->latest_triton_reboot, undef,
			"latest_triton_reboot is not already set" );

		is( $d->set_triton_reboot(), 1, "set_triton_reboot affects 1 row" );
		ok( $d->latest_triton_reboot, "triton_reboot is set on the object" );

		is( Conch::Model::Device->lookup( $d->id )->latest_triton_reboot,
			$d->latest_triton_reboot, "latest_triton_reboot is set in the db" );
	};

	subtest "asset_tag" => sub {
		my $asset_tag = "TEST";
		is( $d->asset_tag, undef, "asset_tag is not already set" );

		is( $d->set_asset_tag($asset_tag), 1, "set_asset_tag affects 1 row" );
		is( $d->asset_tag, $asset_tag,
			"asset_tag matches expectations on the object" );

		is( Conch::Model::Device->lookup( $d->id )->asset_tag,
			$asset_tag, "asset_tag matches expectations" );
	};

	subtest "validated" => sub {
		is( $d->validated, undef,
			"validated is not already set" );

		is( $d->set_validated(), 1);
		ok( $d->validated, "validated is set on the object" );

		is( Conch::Model::Device->lookup( $d->id )->validated,
			$d->validated, "validated is set in the db" );
	};
};

TODO: {
	local $TODO = "Untested methods";
	fail("test device_nic_neighbors");
}

done_testing();
