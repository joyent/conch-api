use Mojo::Base -strict;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;

my $t = Test::Conch->new;
$t->load_fixture('conch_user_global_workspace');

$t->authenticate;

$t->get_ok('/hardware_product')
    ->status_is(200)
    ->json_schema_is('HardwareProducts')
    ->json_is([]);

$t->load_fixture('00-hardware', '01-hardware-profiles');

$t->get_ok('/hardware_product')
    ->status_is(200)
    ->json_schema_is('HardwareProducts');

my $products = $t->tx->res->json;

my $hw_id = $products->[0]{id};
my $vendor_id = $products->[0]{hardware_vendor_id};

$t->get_ok("/hardware_product/$hw_id")
    ->status_is(200)
    ->json_schema_is('HardwareProduct')
    ->json_is($products->[0]);

$t->post_ok('/hardware_product', json => { wat => 'wat' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', superbagof({ path => '/', message => re(qr/properties not allowed/i) }));

$t->post_ok('/hardware_product', json => {
        name => 'sungo',
        hardware_vendor_id => $vendor_id,
        alias => 'sungo',
    })
    ->status_is(303);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('HardwareProduct')
    ->json_cmp_deeply({
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
    ->json_cmp_deeply(bag(@$products, $new_product));

$t->post_ok('/hardware_product', json => {
        name => 'sungo',
        hardware_vendor_id => $vendor_id,
        alias => 'sungo',
    })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'Unique constraint violated on \'name\'' });

$t->post_ok("/hardware_product/$new_hw_id", json => { name => 'sungo2' })
    ->status_is(303);

$new_product->{name} = 'sungo2';
$new_product->{updated} = ignore;

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('HardwareProduct')
    ->json_cmp_deeply($new_product);

$t->get_ok('/hardware_product/foo=sungo')
    ->status_is(404);

$t->get_ok('/hardware_product/name=sungo')
    ->status_is(404);

$t->get_ok('/hardware_product/name=sungo2')
    ->status_is(200)
    ->json_schema_is('HardwareProduct')
    ->json_cmp_deeply($new_product);


my $new_hw_profile;

subtest 'create profile on existing product' => sub {
    $t->post_ok("/hardware_product/$new_hw_id", json => {
            hardware_product_profile => { rack_unit => 1 },
        })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', array_each(superhashof({ message => re(qr/missing property/i) })));

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
            hardware_product_profile => $new_hw_profile,
        })
        ->status_is(303);

    $t->get_ok("/hardware_product/$new_hw_id")
        ->status_is(200)
        ->json_schema_is('HardwareProduct')
        ->json_cmp_deeply({
            $new_product->%*,
            hardware_product_profile => superhashof($new_hw_profile),
        });

    $new_product = $t->tx->res->json;
};

subtest 'update some fields in an existing profile and product' => sub {

    $t->post_ok("/hardware_product/$new_hw_id", json => {
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
        ->json_cmp_deeply($new_product);
};

subtest 'create a new hardware_product_profile in an existing product' => sub {

    $t->app->db_hardware_product_profiles->search({ id => $new_product->{hardware_product_profile}{id} })->delete;

    $t->post_ok("/hardware_product/$new_hw_id", json => {
            hardware_product_profile => {
                rack_unit => 1,
            },
        })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', array_each(superhashof({ message => re(qr/missing property/i) })));

    $t->post_ok("/hardware_product/$new_hw_id",
            json => { hardware_product_profile => $new_hw_profile })
        ->status_is(303);

    $new_product->{hardware_product_profile}->@{qw(id rack_unit psu_total)} = (ignore,2,1);

    $t->get_ok("/hardware_product/$new_hw_id")
        ->status_is(200)
        ->json_schema_is('HardwareProduct')
        ->json_cmp_deeply($new_product);
};

my $another_new_hw_id;
my $new_hw_profile_id;

subtest 'create a hardware product and hardware product profile all together' => sub {
    $t->post_ok('/hardware_product', json => {
            name => 'ether2',
            hardware_vendor_id => $vendor_id,
            alias => 'ether',
            hardware_product_profile => { rack_unit => 1 },
        })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', array_each({ path => re(qr{^/hardware_product_profile/}), message => re(qr/missing property/i) }));

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
            hardware_product_profile => $new_hw_profile,
        })
        ->status_is(303);

    $t->get_ok($t->tx->res->headers->location)
        ->status_is(200)
        ->json_schema_is('HardwareProduct')
        ->json_cmp_deeply({
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
                $new_hw_profile->%*,
                id => ignore,
                hba_firmware => undef,
                sata_hdd_num => undef,
                sata_hdd_size => undef,
                sata_hdd_slots => undef,
                sas_hdd_num => undef,
                sas_hdd_size => undef,
                sas_hdd_slots => undef,
                sata_ssd_num => undef,
                sata_ssd_size => undef,
                sata_ssd_slots => undef,
                sas_ssd_num => undef,
                sas_ssd_size => undef,
                sas_ssd_slots => undef,
                nvme_ssd_num => undef,
                nvme_ssd_size => undef,
                nvme_ssd_slots => undef,
                raid_lun_num => undef,
            }
        });

    $another_new_hw_id = $t->tx->res->json->{id};
    $new_hw_profile_id = $t->tx->res->json->{hardware_product_profile}{id};
};

subtest 'delete a hardware product' => sub {

    $t->delete_ok("/hardware_product/$new_hw_id")
        ->status_is(204);

    $t->delete_ok("/hardware_product/$another_new_hw_id")
        ->status_is(204);

    $t->get_ok("/hardware_product/$new_hw_id")
        ->status_is(404);

    $t->get_ok('/hardware_product')
        ->status_is(200)
        ->json_schema_is('HardwareProducts')
        ->json_cmp_deeply($products);

    ok(
        $t->app->db_hardware_product_profiles
            ->search({ id => $new_hw_profile_id })
            ->get_column('deactivated'),
        'new hardware product profile was deleted',
    );
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
