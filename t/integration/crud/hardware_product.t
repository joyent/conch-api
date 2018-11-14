use Mojo::Base -strict;
use Test::More;
use Test::Warnings;
use Data::UUID;
use Test::Deep;
use Test::Conch;

my $t = Test::Conch->new;
$t->load_fixture('conch_user_global_workspace', '00-hardware', '01-hardware-profiles');

my $uuid = Data::UUID->new;

$t->post_ok(
	"/login" => json => {
		user     => 'conch@conch.joyent.us',
		password => 'conch'
	}
)->status_is(200);
BAIL_OUT("Login failed") if $t->tx->res->code != 200;

$t->get_ok('/hardware_product')
	->status_is(200)
	->json_schema_is('HardwareProducts');

my $products = $t->tx->res->json;

my $hw_id = $products->[0]{id};
my $vendor_id = $products->[0]{hardware_vendor_id};

$t->get_ok("/hardware_product/$hw_id")
	->status_is(200)
	->json_schema_is('HardwareProduct')
	->json_is('', $products->[0]);

$t->post_ok('/hardware_product', json => { wat => 'wat' })
	->status_is(400)
	->json_schema_is('Error');

$t->post_ok('/hardware_product', json => {
		name => 'sungo',
		vendor => $vendor_id,
		hardware_vendor_id => $vendor_id,
		alias => 'sungo',
	})
	->status_is(400, 'cannot provide both vendor and hardware_vendor_id');

$t->post_ok('/hardware_product', json => {
		name => 'sungo',
		hardware_vendor_id => $vendor_id,
		alias => 'sungo',
	})
	->status_is(303);

$t->get_ok($t->tx->res->headers->location)
	->status_is(200)
	->json_schema_is('HardwareProduct')
	->json_cmp_deeply('', {
		id => ignore,
		name => 'sungo',
		alias => 'sungo',
		prefix => undef,
		hardware_vendor_id => $vendor_id,
		created => ignore,
		updated => ignore,
		specification => undef,
		sku => undef,
		generation_name => undef,
		legacy_product_name => undef,
		hardware_product_profile => undef,
	});

my $new_product = $t->tx->res->json;
my $new_hw_id = $new_product->{id};

$t->get_ok('/hardware_product')
	->status_is(200)
	->json_schema_is('HardwareProducts')
	->json_cmp_deeply('', bag(@$products, $new_product));

$t->post_ok('/hardware_product', json => {
		name => 'sungo',
		vendor => $vendor_id,
		alias => 'sungo',
	})
	->status_is(400)
	->json_schema_is('Error')
	->json_is('', { error => 'Unique constraint violated on \'name\'' });

$t->post_ok("/hardware_product/$new_hw_id", json => {
		id => $new_hw_id,
		vendor => $vendor_id,
		hardware_vendor_id => $vendor_id,
	})
	->status_is(400, 'cannot provide both vendor and hardware_vendor_id');

$t->post_ok("/hardware_product/$new_hw_id", json => {
		id => $new_hw_id,
		name => 'sungo2',
	})
	->status_is(303);

$new_product->{name} = 'sungo2';
$new_product->{updated} = ignore;

$t->get_ok($t->tx->res->headers->location)
	->status_is(200)
	->json_schema_is('HardwareProduct')
	->json_cmp_deeply('', $new_product);

$t->get_ok('/hardware_product/name=sungo')
	->status_is(404);

$t->get_ok('/hardware_product/name=sungo2')
	->status_is(200)
	->json_schema_is('HardwareProduct')
	->json_cmp_deeply('', $new_product);


my $new_hw_profile;

subtest 'create profile on existing product' => sub {

	$t->post_ok("/hardware_product/name=$products->[0]{name}", json => {
			id => $new_hw_id,
			name => 'Luci'
		})
		->status_is(400)
		->json_is('', { error => 'mismatch between path and payload' });

	$t->post_ok("/hardware_product/$new_hw_id", json => {
			id => $new_hw_id,
			hardware_product_profile => { rack_unit => 1 },
		})
		->status_is(400, 'missing fields when creating a new hardware product profile');

	$new_hw_profile = {
		rack_unit => 2,
		purpose => 'because',
		bios_firmware => 'kittens',
		cpu_num => 2,
		cpu_type => 'hot',
		dimms_num => 4,
		ram_total => 1024,
		nics_num => 16,
		psu_total => 1,
		usb_num => 4,
	};

	$t->post_ok("/hardware_product/$new_hw_id", json => {
			id => $new_hw_id,
			hardware_product_profile => $new_hw_profile,
		})
		->status_is(303);

	$t->get_ok("/hardware_product/$new_hw_id")
		->status_is(200)
		->json_schema_is('HardwareProduct')
		->json_cmp_deeply('', {
			%$new_product,
			hardware_product_profile => superhashof($new_hw_profile),
		});

	$new_product = $t->tx->res->json;
};

subtest 'update some fields in an existing profile and product' => sub {

	$t->post_ok("/hardware_product/$new_hw_id", json => {
			id => $new_hw_id,
			name => 'ether1',
			hardware_product_profile => {
				rack_unit => 3,
				psu_total => undef,
			},
		})
		->status_is(303);

	$new_product->@{qw(name updated)} = ('ether1',ignore);
	$new_product->{hardware_product_profile}->@{qw(rack_unit psu_total)} = (3,undef);

	$t->get_ok("/hardware_product/$new_hw_id")
		->status_is(200)
		->json_schema_is('HardwareProduct')
		->json_cmp_deeply('', $new_product);

	$t->post_ok("/hardware_product/$new_hw_id", json => {
			id => $new_hw_id,
			hardware_product_profile => {
				zpool_id => $uuid->create_str,
				zpool_profile => { name => 'Luci' },
			},
		})
		->status_is(400, 'cannot provide both zpool_id and zpool_profile');

	$t->post_ok("/hardware_product/$new_hw_id", json => {
			id => $new_hw_id,
			hardware_product_profile => { zpool_id => $uuid->create_str },
		})
		->status_is(400, 'unrecognized zpool_id');
};

subtest 'create a new zpool for an existing profile/product' => sub {

	$t->post_ok("/hardware_product/$new_hw_id", json => {
			id => $new_hw_id,
			hardware_product_profile => {
				zpool_profile => { foo => 'Luci' },
			},
		})
		->status_is(400, 'invalid fields when creating a new zpool profile');

	$t->post_ok("/hardware_product/$new_hw_id", json => {
			id => $new_hw_id,
			hardware_product_profile => {
				zpool_profile => {
					name => 'Luci',
					disk_per => 1,
				},
			},
		})
		->status_is(303);

	$new_product->{hardware_product_profile}{zpool_profile} = {
		id => ignore,
		name => 'Luci',
		vdev_t => undef,
		vdev_n => undef,
		disk_per => 1,
		spare => undef,
		log => undef,
		cache => undef,
	};

	$t->get_ok("/hardware_product/$new_hw_id")
		->status_is(200)
		->json_schema_is('HardwareProduct')
		->json_cmp_deeply('', $new_product);

	$t->post_ok("/hardware_product/$new_hw_id", json => {
			id => $new_hw_id,
			hardware_product_profile => {
				zpool_profile => { name => 'Luci', disk_per => 2 },
			},
		})
		->status_is(400)
		->json_cmp_deeply('', { error => re(qr/duplicate key value violates unique constraint/) });

	my $zog_zpool = $t->app->db_zpool_profiles->create({
		name => 'Zøg',
		disk_per => 11,
	});

	$t->post_ok("/hardware_product/$new_hw_id", json => {
			id => $new_hw_id,
			hardware_product_profile => {
				zpool_profile => { name => 'Zøg' },
			},
		})
		->status_is(303, 'switched zpool profiles, by referencing its name');

	$new_product->{hardware_product_profile}{zpool_profile}->@{qw(id name disk_per)} = ($zog_zpool->id,'Zøg',11);

	$t->get_ok("/hardware_product/$new_hw_id")
		->status_is(200)
		->json_schema_is('HardwareProduct')
		->json_cmp_deeply('', $new_product);
};

subtest 'create a profile and zpool at the same time in an existing product' => sub {

	$t->app->db_zpool_profiles->search({ id => $new_product->{hardware_product_profile}{zpool_id} })->delete;
	$t->app->db_hardware_product_profiles->search({ id => $new_product->{hardware_product_profile}{id} })->delete;

	my $zpool_count = $t->app->db_zpool_profiles->count;

	$t->post_ok("/hardware_product/$new_hw_id", json => {
			id => $new_hw_id,
			hardware_product_profile => {
				zpool_profile => { foo => 'Bean' },
			},
		})
		->status_is(400, 'invalid fields when creating a new zpool profile');

	$t->post_ok("/hardware_product/$new_hw_id", json => {
			id => $new_hw_id,
			hardware_product_profile => {
				zpool_profile => { name => 'Bean' },
				rack_unit => 1,
			},
		})
		->status_is(400, 'missing fields when creating a hew hardware product profile');

	is($t->app->db_ro_zpool_profiles->count, $zpool_count, 'any newly created zpools were rolled back');

	$t->post_ok("/hardware_product/$new_hw_id", json => {
			id => $new_hw_id,
			hardware_product_profile => {
				%$new_hw_profile,
				zpool_profile => {
					name => 'Bean',
					disk_per => 2,
				},
			},
		})
		->status_is(303);

	$new_product->{hardware_product_profile}->@{qw(id rack_unit psu_total)} = (ignore,2,1);
	$new_product->{hardware_product_profile}{zpool_profile}->@{qw(id name disk_per)} = (ignore,'Bean',2);

	$t->get_ok("/hardware_product/$new_hw_id")
		->status_is(200)
		->json_schema_is('HardwareProduct')
		->json_cmp_deeply('', $new_product);
};

my $another_new_hw_id;
my $new_hw_profile_id;

subtest 'create a hardware product, hardware product profile and zpool profile all together' => sub {
	$t->post_ok('/hardware_product', json => {
			name => 'ether2',
			hardware_vendor_id => $vendor_id,
			alias => 'ether',
			hardware_product_profile => { rack_unit => 1 },
		})
		->status_is(400, 'missing fields when creating a new hardware product profile');

	$new_hw_profile = {
		rack_unit => 2,
		purpose => 'because',
		bios_firmware => 'kittens',
		cpu_num => 2,
		cpu_type => 'hot',
		dimms_num => 4,
		ram_total => 1024,
		nics_num => 16,
		psu_total => 1,
		usb_num => 4,
	};

	$t->post_ok('/hardware_product', json => {
			name => 'ether2',
			hardware_vendor_id => $vendor_id,
			alias => 'ether',
			hardware_product_profile => {
				%$new_hw_profile,
				zpool_id => $uuid->create_str,
				zpool_profile => { name => 'Luci' },
			},
		})
		->status_is(400, 'cannot provide both zpool_id and zpool_profile');

	$t->post_ok('/hardware_product', json => {
			name => 'ether2',
			hardware_vendor_id => $vendor_id,
			alias => 'ether',
			hardware_product_profile => {
				%$new_hw_profile,
				zpool_profile => {
					name => 'Luci',
					disk_per => 3,
				},
			},
		})
		->status_is(400, 'zpool_profile name is duplicated');

	$t->post_ok('/hardware_product', json => {
			name => 'ether2',
			hardware_vendor_id => $vendor_id,
			alias => 'ether',
			hardware_product_profile => {
				%$new_hw_profile,
				zpool_profile => {
					name => 'Elfo',
					disk_per => 3,
				},
			},
		})
		->status_is(303);

	$t->get_ok($t->tx->res->headers->location)
		->status_is(200)
		->json_schema_is('HardwareProduct')
		->json_cmp_deeply('', {
			id => ignore,
			name => 'ether2',
			alias => 'ether',
			prefix => undef,
			hardware_vendor_id => $vendor_id,
			created => ignore,
			updated => ignore,
			specification => undef,
			sku => undef,
			generation_name => undef,
			legacy_product_name => undef,
			hardware_product_profile => {
				%$new_hw_profile,
				id => ignore,
				hba_firmware => undef,
				sata_num => undef,
				sata_size => undef,
				sata_slots => undef,
				sas_num => undef,
				sas_size => undef,
				sas_slots => undef,
				ssd_num => undef,
				ssd_size => undef,
				ssd_slots => undef,
				zpool_profile => {
					id => ignore,
					name => 'Elfo',
					vdev_t => undef,
					vdev_n => undef,
					disk_per => 3,
					spare => undef,
					log => undef,
					cache => undef,
				},
			}
		});

	$another_new_hw_id = $t->tx->res->json->{id};
	$new_hw_profile_id = $t->tx->res->json->{hardware_product_profile}{id};
};

subtest 'delete a hardware product' => sub {

	$t->delete_ok("/hardware_product/$new_hw_id")->status_is(204);
	$t->delete_ok("/hardware_product/$another_new_hw_id")->status_is(204);
	$t->get_ok("/hardware_product/$new_hw_id")->status_is(404);

	$t->get_ok('/hardware_product')
		->status_is(200)
		->json_schema_is('HardwareProducts')
		->json_cmp_deeply('', $products);

	ok(
		$t->app->db_hardware_product_profiles
			->search({ id => $new_hw_profile_id })
			->get_column('deactivated'),
		'new hardware product profile was deleted',
	);
};

done_testing();
