use Mojo::Base -strict;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;
use Conch::UUID 'create_uuid_str';

my $t = Test::Conch->new;
$t->load_fixture('super_user');

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
my $validation_plan_id = $products->[0]{validation_plan_id};

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
        rack_unit_size => 2,
        sku => 'my sku',
        validation_plan_id => $validation_plan_id,
    })
    ->status_is(303)
    ->location_like(qr!^/hardware_product/${\Conch::UUID::UUID_FORMAT}$!);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('HardwareProduct')
    ->json_cmp_deeply({
        id => re(Conch::UUID::UUID_FORMAT),
        name => 'sungo',
        alias => 'sungo',
        prefix => undef,
        hardware_vendor_id => $vendor_id,
        created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        updated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        specification => undef,
        sku => 'my sku',
        generation_name => undef,
        legacy_product_name => undef,
        rack_unit_size => 2,
        hardware_product_profile => undef,
        validation_plan_id => $validation_plan_id,
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
        sku => 'another sku',
        rack_unit_size => 1,
        validation_plan_id => $validation_plan_id,
    })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'Unique constraint violated on \'name\'' });

$t->post_ok('/hardware_product', json => {
        name => 'another name',
        hardware_vendor_id => create_uuid_str(),
        alias => 'another alias',
        sku => 'another sku',
        rack_unit_size => 1,
        validation_plan_id => $validation_plan_id,
    })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'hardware_vendor_id does not exist' });

$t->post_ok('/hardware_product', json => {
        name => 'another name',
        hardware_vendor_id => $vendor_id,
        alias => 'another alias',
        sku => 'another sku',
        rack_unit_size => 1,
        validation_plan_id => create_uuid_str(),
    })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'validation_plan_id does not exist' });

$t->post_ok("/hardware_product/$new_hw_id", json => { name => 'sungo2' })
    ->status_is(303)
    ->location_is('/hardware_product/'.$new_hw_id);

$new_product->{name} = 'sungo2';
$new_product->{updated} = re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/);

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
            hardware_product_profile => { bios_firmware => 'foo' },
        })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', array_each(superhashof({ message => re(qr/missing property/i) })));

    $new_hw_profile = {
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
        ->status_is(303)
        ->location_is('/hardware_product/'.$new_hw_id);

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
    $t->post_ok("/hardware_product/$new_hw_id", json => { name => 'Switch' })
        ->status_is(409)
        ->json_schema_is('Error')
        ->json_is({ error => 'Unique constraint violated on \'name\'' });

    $t->post_ok("/hardware_product/$new_hw_id", json => { alias => 'Switch Vendor' })
        ->status_is(409)
        ->json_schema_is('Error')
        ->json_is({ error => 'Unique constraint violated on \'alias\'' });

    $t->post_ok("/hardware_product/$new_hw_id", json => { sku => '550-551-001' })
        ->status_is(409)
        ->json_schema_is('Error')
        ->json_is({ error => 'Unique constraint violated on \'sku\'' });

    $t->post_ok("/hardware_product/$new_hw_id", json => { hardware_vendor_id => create_uuid_str() })
        ->status_is(409)
        ->json_schema_is('Error')
        ->json_is({ error => 'hardware_vendor_id does not exist' });

    $t->post_ok("/hardware_product/$new_hw_id", json => { validation_plan_id => create_uuid_str() })
        ->status_is(409)
        ->json_schema_is('Error')
        ->json_is({ error => 'validation_plan_id does not exist' });

    $t->post_ok("/hardware_product/$new_hw_id", json => {
            name => 'ether1',
            rack_unit_size => 4,
            hardware_product_profile => {
                dimms_num => 3,
                psu_total => undef,
            },
        })
        ->status_is(303)
        ->location_is('/hardware_product/'.$new_hw_id);

    $new_product->@{qw(name rack_unit_size updated)} = ('ether1',4,re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/));
    $new_product->{hardware_product_profile}->@{qw(dimms_num psu_total)} = (3,undef);

    $t->get_ok("/hardware_product/$new_hw_id")
        ->status_is(200)
        ->json_schema_is('HardwareProduct')
        ->json_cmp_deeply($new_product);
};

subtest 'create a new hardware_product_profile in an existing product' => sub {

    $t->app->db_hardware_product_profiles->search({ id => $new_product->{hardware_product_profile}{id} })->delete;

    $t->post_ok("/hardware_product/$new_hw_id", json => {
            hardware_product_profile => {
                dimms_num => 2,
            },
        })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', array_each(superhashof({ message => re(qr/missing property/i) })));

    $t->post_ok("/hardware_product/$new_hw_id",
            json => { hardware_product_profile => $new_hw_profile })
        ->status_is(303)
        ->location_is('/hardware_product/'.$new_hw_id);

    $new_product->{hardware_product_profile}->@{qw(id dimms_num psu_total)} = (re(Conch::UUID::UUID_FORMAT),4,1);

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
            sku => 'another sku',
            rack_unit_size => 1,
            hardware_product_profile => { dimms_num => 2 },
            validation_plan_id => $validation_plan_id,
        })
        ->status_is(400)
        ->json_schema_is('RequestValidationError')
        ->json_cmp_deeply('/details', array_each({ path => re(qr{^/hardware_product_profile/}), message => re(qr/missing property/i) }));

    $new_hw_profile = {
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
            sku => 'another sku',
            rack_unit_size => 2,
            hardware_product_profile => $new_hw_profile,
            validation_plan_id => $validation_plan_id,
        })
        ->status_is(303)
        ->location_like(qr!^/hardware_product/${\Conch::UUID::UUID_FORMAT}$!);

    $t->get_ok($t->tx->res->headers->location)
        ->status_is(200)
        ->json_schema_is('HardwareProduct')
        ->json_cmp_deeply({
            id => re(Conch::UUID::UUID_FORMAT),
            name => 'ether2',
            alias => 'ether',
            prefix => undef,
            hardware_vendor_id => $vendor_id,
            created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            updated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            specification => undef,
            sku => 'another sku',
            generation_name => undef,
            legacy_product_name => undef,
            rack_unit_size => 2,
            validation_plan_id => $validation_plan_id,
            hardware_product_profile => {
                $new_hw_profile->%*,
                id => re(Conch::UUID::UUID_FORMAT),
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
