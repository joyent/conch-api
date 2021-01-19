use Mojo::Base -strict;
use open ':std', ':encoding(UTF-8)'; # force stdin, stdout, stderr into utf8

use Test::More;
use Test::Warnings;
use Test::Deep;
use Test::Conch;
use Conch::UUID 'create_uuid_str';
use Mojo::Util 'url_escape';
use Mojo::JSON 'from_json';

my $t = Test::Conch->new;
my $base_uri = $t->ua->server->url; # used as the base uri for all requests
my $super_user = $t->load_fixture('super_user');
my $other_user = $t->generate_fixtures('user_account');

my $json_schema = $t->load_fixture('json_schema_hardware_product_specification');

$t->authenticate;

my $t_other = Test::Conch->new(pg => $t->pg);
$t_other->authenticate(email => $other_user->email);

$t->get_ok('/hardware_product')
    ->status_is(200)
    ->json_schema_is('HardwareProducts')
    ->json_is([]);

$t->load_fixture('00-hardware');

$t->get_ok('/hardware_product')
    ->status_is(200)
    ->json_schema_is('HardwareProducts');

my $products = $t->tx->res->json;
my ($hw_id, $hw_name) = $products->[0]->@{qw(id name)};

$t->get_ok('/hardware_product/'.create_uuid_str())
    ->status_is(404)
    ->log_debug_like(qr/^Looking up a hardware product by id ${\Conch::UUID::UUID_FORMAT}$/);

$t->get_ok("/hardware_product/$hw_id")
    ->status_is(200)
    ->json_schema_is('HardwareProduct')
    ->json_cmp_deeply(superhashof($products->[0]));

my $vendor_id = $t->tx->res->json->{hardware_vendor_id};
my $validation_plan_id = $t->tx->res->json->{validation_plan_id};

$t->post_ok('/hardware_product', json => { wat => 'wat' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [
        superhashof({ error => 'additional property not permitted' }),
        superhashof({ error => 'missing properties: alias, hardware_vendor_id, rack_unit_size, purpose' }),
        superhashof({ error => 'missing properties: name, sku, validation_plan_id, bios_firmware' }),
        superhashof({ error => 'missing property: device_report' }),
    ]);

$t->post_ok('/hardware_product', json => { name => 'sungo', alias => 'sungo' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [
        superhashof({ error => 'missing properties: hardware_vendor_id, rack_unit_size, purpose' }),
        superhashof({ error => 'missing properties: sku, validation_plan_id, bios_firmware' }),
        superhashof({ error => 'missing property: device_report' }),
    ]);

my %hw_fields = (
    name => 'sungo',
    hardware_vendor_id => $vendor_id,
    alias => 'sungo',
    rack_unit_size => 2,
    sku => 'my sku',
    validation_plan_id => $validation_plan_id,
    purpose => 'myself',
    bios_firmware => '1.2.3',
);

$t->post_ok('/hardware_product', json => { %hw_fields, specification => 'not json!' } )
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', my $create_errors = [
      {
        data_location => '/specification',
        schema_location => '/$ref/properties/specification/$ref/type',
        absolute_schema_location => $base_uri.'json_schema/hardware_product/specification/1#/type',
        error => 'wrong type (expected object)',
      },
      {
        data_location => '/specification',
        schema_location => '/$ref/properties/specification/type',
        absolute_schema_location => $base_uri.'json_schema/request/HardwareProductUpdate#/properties/specification/type',
        error => 'wrong type (expected object)',
      },
    ]);

$t->post_ok('/hardware_product', json => { %hw_fields, specification => '{"disk_size":"not an object"}' } )
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', $create_errors);

$t->post_ok('/hardware_product', json => { %hw_fields, specification => { disk_size => 'not an object' } })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply({
      error => 'request did not match required format',
      schema => $base_uri.'json_schema/request/HardwareProductCreate',
      details => [ {
        data_location => '/specification/disk_size',
        schema_location => '/$ref/properties/specification/$ref/properties/disk_size/type',
        absolute_schema_location => $base_uri.'json_schema/hardware_product/specification/1#/properties/disk_size/type',
        error => 'wrong type (expected object)',
      }],
    });

$t->post_ok('/json_schema/hardware_product/specification', json =>
  do {
    my $s = from_json($json_schema->body);
    $s->{properties}{disk_size} = JSON::PP::true;
    $s;
  })
  ->status_is(201)
  ->location_like(qr!^/json_schema/${\Conch::UUID::UUID_FORMAT}$!)
  ->header_is('Content-Location', '/json_schema/hardware_product/specification/2');

$t->post_ok('/hardware_product', json => {
    %hw_fields,
    name => 'ether1',
    alias => 'ether1',
    sku => 'ether sku',
    specification => { disk_size => 'not an object' },
  })
  ->status_is(201)
  ->location_like(qr!^/hardware_product/${\Conch::UUID::UUID_FORMAT}$!);

$t->app->db_hardware_products->search({ name => 'ether1' })->delete;

$hw_fields{specification} = { disk_size => { _default => 0, AcmeCorp => 512 } };
$t->post_ok('/hardware_product', json => \%hw_fields)
    ->status_is(201)
    ->location_like(qr!^/hardware_product/${\Conch::UUID::UUID_FORMAT}$!);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('HardwareProduct')
    ->json_cmp_deeply({
        %hw_fields,
        id => re(Conch::UUID::UUID_FORMAT),
        prefix => undef,
        created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        updated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        generation_name => undef,
        legacy_product_name => undef,
        hba_firmware => undef,
        cpu_num => 0,
        cpu_type => undef,
        dimms_num => 0,
        ram_total => 0,
        nics_num => 0,
        sata_hdd_num => 0,
        sata_hdd_size => undef,
        sata_hdd_slots => undef,
        sas_hdd_num => 0,
        sas_hdd_size => undef,
        sas_hdd_slots => undef,
        sata_ssd_num => 0,
        sata_ssd_size => undef,
        sata_ssd_slots => undef,
        sas_ssd_num => 0,
        sas_ssd_size => undef,
        sas_ssd_slots => undef,
        nvme_ssd_num => 0,
        nvme_ssd_size => undef,
        nvme_ssd_slots => undef,
        raid_lun_num => 0,
        psu_total => 0,
        usb_num => 0,
    });

my $new_product = $t->tx->res->json;
my $new_hw_id = $new_product->{id};

$t->get_ok('/hardware_product')
    ->status_is(200)
    ->json_schema_is('HardwareProducts')
    ->json_cmp_deeply(bag(@$products, +{ $new_product->%{qw(id name alias generation_name sku created updated)} }));

$t->post_ok('/hardware_product', json => {
        name => 'sungo',
        hardware_vendor_id => $vendor_id,
        alias => 'sungo',
        sku => 'another sku',
        rack_unit_size => 1,
        validation_plan_id => $validation_plan_id,
        purpose => 'nothing',
        bios_firmware => '0',
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
        purpose => 'nothing',
        bios_firmware => '0',
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
        purpose => 'nothing',
        bios_firmware => '0',
    })
    ->status_is(409)
    ->json_schema_is('Error')
    ->json_is({ error => 'validation_plan_id does not exist' });

$t->post_ok('/hardware_product', json => {
    alias => 'another alias',
    hardware_vendor_id => $vendor_id,
    rack_unit_size => 1,
    purpose => 'nothing',
  })
  ->status_is(400)
  ->json_schema_is('RequestValidationError')
  ->json_cmp_deeply('/details', [
    {
      data_location => '',
      schema_location => '/anyOf/0/required',
      absolute_schema_location => $base_uri.'json_schema/request/HardwareProductCreate#/anyOf/0/required',
      error => 'missing properties: name, sku, validation_plan_id, bios_firmware',
    },
    {
      data_location => '',
      schema_location => '/anyOf/1/required',
      absolute_schema_location => $base_uri.'json_schema/request/HardwareProductCreate#/anyOf/1/required',
      error => 'missing property: device_report',
    },
  ]);

$t->post_ok('/hardware_product', json => my $args ={
    alias => 'another alias',
    hardware_vendor_id => $vendor_id,
    rack_unit_size => 1,
    purpose => 'my purpose',
    device_report => {
      report_version => 'v3.2',
      bios_version => 'my bios',
      product_name => 'my product name',
      sku => 'another sku',
      serial_number => 'my_serial',
      system_uuid => create_uuid_str,
      # no device_type, and 'server' plan does not exist
      cpus => [ {} ],
      dimms => [
        { 'memory-locator' => '' },
        { 'memory-locator' => '', 'memory-size' => 20 },
        { 'memory-locator' => '', 'memory-type' => undef },
      ],
      interfaces => {
        foo => { mac => '00:00:00:00:00:00', product => '', vendor => '' },
        bar => { mac => '00:00:00:00:00:00', product => '', vendor => '' },
        baz => { mac => '00:00:00:00:00:00', product => '', vendor => '' },
      },
      disks => {
        a => {},
        b => { drive_type => 'NVME_SSD' },
        c => { drive_type => 'RAID_LUN' },
        d => { drive_type => 'SAS_HDD' },
        e => { drive_type => 'SAS_SSD' },
        f => { drive_type => 'SATA_HDD' },
        g => { drive_type => 'SATA_SSD' },
        h => { transport => 'usb' },
      },
    },
  })
  ->status_is(409)
  ->json_schema_is('Error')
  ->json_is({ error => 'cannot determine validation_plan_id from device_type' });

$args->{device_report}{device_type} = 'server';
$t->post_ok('/hardware_product', json => $args)
  ->status_is(409)
  ->json_schema_is('Error')
  ->json_is({ error => 'cannot determine validation_plan_id from device_type' });

my $server_plan = $t->app->db_legacy_validation_plans->create({ name => 'The Server Plan', description => 'hi' });

$t->post_ok('/hardware_product', json => $args)
  ->status_is(201)
  ->location_like(qr!^/hardware_product/${\Conch::UUID::UUID_FORMAT}$!);

$t->get_ok($t->tx->res->headers->location)
  ->status_is(200)
  ->json_schema_is('HardwareProduct')
  ->json_cmp_deeply({
    name => 'my product name',
    hardware_vendor_id => $vendor_id,
    alias => 'another alias',
    rack_unit_size => 1,
    sku => 'another sku',
    purpose => 'my purpose',
    bios_firmware => 'my bios',
    id => re(Conch::UUID::UUID_FORMAT),
    validation_plan_id => $server_plan->id,
    prefix => undef,
    specification => {},
    created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
    updated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
    generation_name => undef,
    legacy_product_name => undef,
    hba_firmware => undef,
    cpu_num => 1,
    cpu_type => undef,
    dimms_num => 1,
    ram_total => 20,
    nics_num => 3,
    nvme_ssd_num => 1,
    nvme_ssd_size => undef,
    nvme_ssd_slots => undef,
    raid_lun_num => 1,
    sas_hdd_num => 1,
    sas_hdd_size => undef,
    sas_hdd_slots => undef,
    sas_ssd_num => 1,
    sas_ssd_size => undef,
    sas_ssd_slots => undef,
    sata_hdd_num => 1,
    sata_hdd_size => undef,
    sata_hdd_slots => undef,
    sata_ssd_num => 1,
    sata_ssd_size => undef,
    sata_ssd_slots => undef,
    psu_total => 0,
    usb_num => 1,
  });

$t->delete_ok('/hardware_product/'.$t->tx->res->json->{id})
  ->status_is(204);


$t->post_ok("/hardware_product/$new_hw_id", json => { specification => 'not json!' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', my $update_errors = [
      {
        data_location => '/specification',
        schema_location => '/properties/specification/$ref/type',
        absolute_schema_location => $base_uri.'json_schema/hardware_product/specification/2#/type',
        error => 'wrong type (expected object)',
      },
      {
        data_location => '/specification',
        schema_location => '/properties/specification/type',
        absolute_schema_location => $base_uri.'json_schema/request/HardwareProductUpdate#/properties/specification/type',
        error => 'wrong type (expected object)',
      },
    ]);

$t->app->db_json_schemas->resource('hardware_product', 'specification', 'latest')->deactivate;

# we properly detect that the hw spec schema changed (even going backwards!) and re-load version 1
$t->post_ok("/hardware_product/$new_hw_id", json => { specification => '{"disk_size":"not an object"}' })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply('/details', [
      {
        $update_errors->[0]->%*,
        absolute_schema_location => $update_errors->[0]{absolute_schema_location} =~ s/2#/1#/r,
      },
      $update_errors->[1],
    ]);

$t->post_ok("/hardware_product/$new_hw_id", json => { specification => { disk_size => 'not an object' } })
    ->status_is(400)
    ->json_schema_is('RequestValidationError')
    ->json_cmp_deeply({
        error => 'request did not match required format',
        details => [ superhashof({ data_location => '/specification/disk_size', error => 'wrong type (expected object)' }) ],
        schema => $base_uri.'json_schema/request/HardwareProductUpdate',
    });

$t->post_ok("/hardware_product/$new_hw_id", json => { name => 'sungo2' })
    ->status_is(204)
    ->location_is('/hardware_product/'.$new_hw_id);

$new_product->{name} = 'sungo2';
$new_product->{updated} = re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/);

$t->get_ok($t->tx->res->headers->location)
    ->status_is(200)
    ->json_schema_is('HardwareProduct')
    ->json_cmp_deeply($new_product);

$t->get_ok('/hardware_product/foo')
    ->status_is(404)
    ->log_debug_is('Looking up a hardware product by sku,name,alias foo');

$t->get_ok('/hardware_product/name=sungo2')
    ->status_is(308)
    ->location_is('/hardware_product/sungo2');

$t->get_ok('/hardware_product/name=product_with_alias=foobar')
    ->status_is(308)
    ->location_is('/hardware_product/product_with_alias=foobar');

$t->get_ok('/hardware_product/name=sungo2/specification')
    ->status_is(308)
    ->location_is('/hardware_product/sungo2/specification');

$t->put_ok('/hardware_product/name=sungo2/specification?path=/sku=foo/DEADBEEF', json => 1)
    ->status_is(308)
    ->location_is('/hardware_product/sungo2/specification?path='.url_escape('/sku=foo/DEADBEEF'));

$t->get_ok($_)
    ->status_is(200)
    ->location_is('/hardware_product/'.$new_product->{id})
    ->json_schema_is('HardwareProduct')
    ->json_cmp_deeply($new_product)
    foreach
        '/hardware_product/'.$new_product->{id},
        '/hardware_product/my sku',     # sku
        '/hardware_product/sungo2',     # name  TODO: remove later
        '/hardware_product/sungo';      # alias TODO: remove later

$t->post_ok('/hardware_product', json => {
        name => 'sungo3',
        alias => 'my sku',  # these two fields are
        sku => 'sungo',     # flipped from the other product
        hardware_vendor_id => $vendor_id,
        rack_unit_size => 2,
        validation_plan_id => $validation_plan_id,
        purpose => 'myself',
        bios_firmware => '1.2.3',
    })
    ->status_is(201)
    ->location_like(qr!^/hardware_product/${\Conch::UUID::UUID_FORMAT}$!);

$t->get_ok('/hardware_product/sungo')
    ->status_is(409)
    ->json_is({ error => 'there is more than one match' });

my $base_specification = $hw_fields{specification} = {
  disk_size => { _default => 0, AcmeCorp => 512 },
};

subtest 'manipulate hardware_product.specification' => sub {
  $t->put_ok('/hardware_product/'.$new_hw_id.'/specification', json => {})
    ->status_is(400)
    ->json_schema_is('QueryParamsValidationError')
    ->json_cmp_deeply('/details', [ superhashof({ error => 'missing property: path' }) ]);

  $t->put_ok('/hardware_product/'.$new_hw_id.'/specification?path=', json => $base_specification)
    ->status_is(204)
    ->location_is('/hardware_product/'.$new_hw_id);

  $t->get_ok('/hardware_product/'.$new_hw_id)
    ->status_is(200)
    ->json_schema_is('HardwareProduct')
    ->json_cmp_deeply(superhashof({ specification => $base_specification }));

  $t->put_ok('/hardware_product/'.$new_hw_id.'/specification?path=', json => 'hello')
    ->status_is(409)
    ->json_schema_is('ValidationError')
    ->json_cmp_deeply({
      error => 'new specification field did not match required format',
      schema => $base_uri.'json_schema/hardware_product/specification/1',
      data => 'hello',
      details => [
        {
          data_location => '',
          schema_location => '/type',
          absolute_schema_location => $base_uri.'json_schema/hardware_product/specification/1#/type',
          error => 'wrong type (expected object)',
        }
      ]
    });

  $t->put_ok('/hardware_product/'.$new_hw_id.'/specification?path=/disk_size', json => 1)
    ->status_is(409)
    ->json_schema_is('ValidationError')
    ->json_cmp_deeply({
      error => 'new specification field did not match required format',
      schema => $base_uri.'json_schema/hardware_product/specification/1',
      data => { disk_size => 1 },
      details => [
        {
          data_location => '/disk_size',
          schema_location => '/properties/disk_size/type',
          absolute_schema_location => $base_uri.'json_schema/hardware_product/specification/1#/properties/disk_size/type',
          error => 'wrong type (expected object)',
        }
      ]
   });

  $t->put_ok('/hardware_product/'.$new_hw_id.'/specification?path=/disk_size',
      json => { _default => 128 })
    ->status_is(204)
    ->location_is('/hardware_product/'.$new_hw_id);

  $t->get_ok('/hardware_product/'.$new_hw_id)
    ->status_is(200)
    ->json_schema_is('HardwareProduct')
    ->json_cmp_deeply(superhashof({
      specification => {
        $base_specification->%*,
        disk_size => { _default => 128 },
      },
    }));

  $t->put_ok('/hardware_product/'.$new_hw_id.'/specification?path=/disk_size/SEAGATE_8000',
      json => {})
    ->status_is(409)
    ->json_schema_is('ValidationError')
    ->json_cmp_deeply({
      error => 'new specification field did not match required format',
      schema => $base_uri.'json_schema/hardware_product/specification/1',
      data => { disk_size => { SEAGATE_8000 => {}, _default => 128 } },
      details => [
        {
          data_location => '/disk_size/SEAGATE_8000',
          schema_location => '/properties/disk_size/additionalProperties/type',
          absolute_schema_location => $base_uri.'json_schema/hardware_product/specification/1#/properties/disk_size/additionalProperties/type',
          error => 'wrong type (expected integer)',
        }
      ]
   });

  $t->put_ok('/hardware_product/'.$new_hw_id.'/specification?path=/disk_size/SEAGATE_8000',
      json => 1)
    ->status_is(204)
    ->location_is('/hardware_product/'.$new_hw_id);

  $t->get_ok('/hardware_product/'.$new_hw_id)
    ->status_is(200)
    ->json_schema_is('HardwareProduct')
    ->json_cmp_deeply(superhashof({
      specification => {
        $base_specification->%*,
        disk_size => { _default => 128, SEAGATE_8000 => 1 },
      },
    }));

  $t->put_ok('/hardware_product/'.$new_hw_id.'/specification?path=/disk_size/_default', json => 64)
    ->status_is(204)
    ->location_is('/hardware_product/'.$new_hw_id);

  $t->get_ok('/hardware_product/'.$new_hw_id)
    ->status_is(200)
    ->json_schema_is('HardwareProduct')
    ->json_cmp_deeply(superhashof({
      specification => {
        $base_specification->%*,
        disk_size => { _default => 64, SEAGATE_8000 => 1 },
      },
    }));

  # the path we want to operate on is called .../~1~device/  and encodes as .../~01~0device/...
  $t->put_ok('/hardware_product/'.$new_hw_id.'/specification?path=/disk_size/tilde~1~device', json => 2)
    ->status_is(400)
    ->json_schema_is('QueryParamsValidationError')
    ->json_cmp_deeply('/details', [ superhashof({ error => 'not a json-pointer' }) ]);

  $t->put_ok('/hardware_product/'.$new_hw_id.'/specification?path=/disk_size/tilde~01~0device', json => 2)
    ->status_is(204)
    ->location_is('/hardware_product/'.$new_hw_id);

  $t->get_ok('/hardware_product/'.$new_hw_id)
    ->status_is(200)
    ->json_schema_is('HardwareProduct')
    ->json_cmp_deeply(superhashof({
      specification => {
        $base_specification->%*,
        disk_size => {
          _default => 64,
          SEAGATE_8000 => 1,
          'tilde~1~device' => 2,
        },
      },
    }));

  $t->put_ok('/hardware_product/'.$new_hw_id.'/specification?path=/disks',
      json => { usb_hdd_num => 0 })
    ->status_is(204)
    ->location_is('/hardware_product/'.$new_hw_id);

  $t->get_ok('/hardware_product/'.$new_hw_id)
    ->status_is(200)
    ->json_schema_is('HardwareProduct')
    ->json_cmp_deeply(superhashof({
      specification => {
        $base_specification->%*,
        disk_size => { _default => 64, SEAGATE_8000 => 1, 'tilde~1~device' => 2 },
        disks => { usb_hdd_num => 0 },
      },
    }));

  $t->put_ok('/hardware_product/'.$new_hw_id.'/specification?path=/disks',
      json => { usb_hdd_num => 0, sas_ssd_slots => '1,2,3' })
    ->status_is(204)
    ->location_is('/hardware_product/'.$new_hw_id);

  $t->get_ok('/hardware_product/'.$new_hw_id)
    ->status_is(200)
    ->json_schema_is('HardwareProduct')
    ->json_cmp_deeply(superhashof({
      specification => {
        $base_specification->%*,
        disk_size => { _default => 64, SEAGATE_8000 => 1, 'tilde~1~device' => 2 },
        disks => { usb_hdd_num => 0, sas_ssd_slots => '1,2,3' },
      },
    }));

  $t->delete_ok('/hardware_product/'.$new_hw_id.'/specification')
    ->status_is(400)
    ->json_schema_is('QueryParamsValidationError')
    ->json_cmp_deeply('/details', [ superhashof({ error => 'missing property: path' }) ]);

  # the path we want to operate on is called .../~1~device/  and encodes as .../~01~0device/...
  $t->delete_ok('/hardware_product/'.$new_hw_id.'/specification?path=/disk_size/tilde~1~device')
    ->status_is(400)
    ->json_schema_is('QueryParamsValidationError')
    ->json_cmp_deeply('/details', [ superhashof({ error => 'not a json-pointer' }) ]);

  $t->delete_ok('/hardware_product/'.$new_hw_id.'/specification?path=/disk_size/_default')
    ->status_is(409)
    ->json_schema_is('ValidationError')
    ->json_cmp_deeply({
      error => 'new specification field did not match required format',
      schema => $base_uri.'json_schema/hardware_product/specification/1',
      data => {
        disk_size => { SEAGATE_8000 => 1, 'tilde~1~device' => 2 },
        disks => { usb_hdd_num => 0, sas_ssd_slots => '1,2,3' },
      },
      details => [
        {
          data_location => '/disk_size',
          schema_location => '/properties/disk_size/required',
          absolute_schema_location => $base_uri.'json_schema/hardware_product/specification/1#/properties/disk_size/required',
          error => 'missing property: _default',
        }
      ]
   });

  $t->delete_ok('/hardware_product/'.$new_hw_id.'/specification?path=/disk_size/tilde~01~0device')
    ->status_is(204)
    ->location_is('/hardware_product/'.$new_hw_id);

  $t->get_ok('/hardware_product/'.$new_hw_id)
    ->status_is(200)
    ->json_schema_is('HardwareProduct')
    ->json_cmp_deeply(superhashof({
      specification => {
        $base_specification->%*,
        disk_size => { _default => 64, SEAGATE_8000 => 1 },
        disks => { usb_hdd_num => 0, sas_ssd_slots => '1,2,3' },
      },
    }));

  $t->delete_ok('/hardware_product/'.$new_hw_id.'/specification?path=/disk_size')
    ->status_is(204)
    ->location_is('/hardware_product/'.$new_hw_id);

  $t->get_ok('/hardware_product/'.$new_hw_id)
    ->status_is(200)
    ->json_schema_is('HardwareProduct')
    ->json_cmp_deeply(superhashof({
      specification => {
        $base_specification->%{ grep $_ ne 'disk_size', keys $base_specification->%* },
        disks => { usb_hdd_num => 0, sas_ssd_slots => '1,2,3' },
      },
    }));

  $t->delete_ok('/hardware_product/'.$new_hw_id.'/specification?path=/disks/usb_hdd_num')
    ->status_is(204)
    ->location_is('/hardware_product/'.$new_hw_id);

  $t->get_ok('/hardware_product/'.$new_hw_id)
    ->status_is(200)
    ->json_schema_is('HardwareProduct')
    ->json_cmp_deeply(superhashof({
      specification => {
        $base_specification->%{ grep $_ ne 'disk_size', keys $base_specification->%* },
        disks => { sas_ssd_slots => '1,2,3' },
      },
    }));
};

subtest 'delete a hardware product' => sub {
    $t->delete_ok("/hardware_product/$new_hw_id")
        ->status_is(204);

    $t->get_ok("/hardware_product/$new_hw_id")
        ->status_is(410);

    $t->delete_ok('/hardware_product/sungo')
        ->status_is(204);

    $t->get_ok('/hardware_product')
        ->status_is(200)
        ->json_schema_is('HardwareProducts')
        ->json_cmp_deeply($products);
};

use constant SPEC_URL => 'https://json-schema.org/draft/2019-09/schema';

subtest 'hardware_products and json_schemas' => sub {
  my ($t_super, $t) = ($t, undef);

  my $ro_user = $t_super->load_fixture('ro_user');
  my $t_ro = Test::Conch->new(pg => $t_super->pg);
  $t_ro->authenticate(email => $ro_user->email);

  $_->get_ok('/hardware_product/'.$hw_id.'/json_schema')
    ->status_is(200)
    ->json_schema_is('HardwareJSONSchemaDescriptions')
    ->json_is([])
    foreach $t_super, $t_ro, $t_other;

  $_->get_ok('/hardware_product/'.$hw_name.'/json_schema')
    ->status_is(200)
    ->json_schema_is('HardwareJSONSchemaDescriptions')
    ->json_is([])
    foreach $t_super, $t_ro, $t_other;

  # /json_schema/firmware/sku123/1
  $t_ro->post_ok('/json_schema/firmware/sku123', json => {
      '$schema' => SPEC_URL,
      description => 'firmware validation for 123',
      type => 'object',
      properties => { a => { type => 'string' } },
    })
    ->status_is(201);
  my ($main_id) = ($t_ro->tx->res->headers->location =~ m!/([^/]+)$!);

  $t_ro->get_ok('/json_schema/firmware')
    ->status_is(200)
    ->json_schema_is('JSONSchemaDescriptions')
    ->json_cmp_deeply([
      my $main_schema_description = {
        id => $main_id,
        '$id' => '/json_schema/firmware/sku123/1',
        description => 'firmware validation for 123',
        type => 'firmware',
        name => 'sku123',
        version => 1,
        latest => JSON::PP::true,
        created => ignore,
        created_user => { map +($_ => $ro_user->$_), qw(id name email) },
        deactivated => undef,
      },
    ]);

  $t_ro->get_ok('/json_schema/firmware?with_hardware_products=1')
    ->status_is(200)
    ->json_schema_is('JSONSchemaDescriptions')
    ->json_cmp_deeply([
      {
        $main_schema_description->%*,
        hardware_products => [],
      },
    ]);

  $t_super->post_ok('/hardware_product/'.$hw_id.'/json_schema/'.create_uuid_str)
    ->status_is(404)
    ->log_debug_like(qr/^Could not find JSON Schema ${\Conch::UUID::UUID_FORMAT}$/);

  $t_ro->post_ok('/hardware_product/'.$hw_id.'/json_schema/'.$_)
    ->status_is(403)
    ->log_debug_is('User must be system admin')
      foreach ($main_id, 'firmware/sku123/2');

  $t_super->post_ok('/hardware_product/'.$hw_id.'/json_schema/'.$main_id)
    ->status_is(201)
    ->location_is('/hardware_product/'.$hw_id.'/json_schema');

  $t_super->post_ok('/hardware_product/'.$hw_id.'/json_schema/'.$main_id)
    ->status_is(204);

  $t_ro->get_ok('/hardware_product/'.$hw_id.'/json_schema')
    ->status_is(200)
    ->json_schema_is('HardwareJSONSchemaDescriptions')
    ->json_cmp_deeply([
      my $main_hardware_description = {
        id => $main_id,
        '$id' => '/json_schema/firmware/sku123/1',
        description => 'firmware validation for 123',
        type => 'firmware',
        name => 'sku123',
        version => 1,
        latest => JSON::PP::true,
        created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        created_user => { map +($_ => $ro_user->$_), qw(id name email) },
        added => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        added_user => { map +($_ => $super_user->$_), qw(id name email) },
      },
    ]);

  $t_ro->get_ok('/hardware_product/'.$hw_name.'/json_schema')
    ->status_is(200)
    ->json_schema_is('HardwareJSONSchemaDescriptions')
    ->json_cmp_deeply([ $main_hardware_description ]);

  # .../latest is not supported here, because it implies that when a new schema in the type-name
  # series is added, the hardware_product association is updated to match, which is not true
  $t_super->post_ok('/hardware_product/'.$products->[0]{name}.'/json_schema/firmware/sku123/latest')
    ->status_is(404);

  $t_ro->get_ok('/json_schema/firmware?with_hardware_products=1')
    ->status_is(200)
    ->json_schema_is('JSONSchemaDescriptions')
    ->json_cmp_deeply([
      {
        $main_schema_description->%*,
        hardware_products => [ $products->[0] ],
      },
    ]);

  # /json_schema/firmware/sku123/2
  $t_ro->post_ok('/json_schema/firmware/sku123', json => {
      '$schema' => SPEC_URL,
      description => 'another hardware schema',
      type => 'object',
      properties => { z => { type => 'string' } },
    })
    ->status_is(201)
    ->location_like(qr!^/json_schema/${\Conch::UUID::UUID_FORMAT}$!);
  my ($second_id) = ($t_ro->tx->res->headers->location =~ m!/([^/]+)$!);

  $main_schema_description->{latest} = JSON::PP::false;
  $main_hardware_description->{latest} = JSON::PP::false;

  $t_ro->get_ok('/json_schema/firmware')
    ->status_is(200)
    ->json_schema_is('JSONSchemaDescriptions')
    ->json_cmp_deeply([
      $main_schema_description,
      my $second_schema_description = {
        id => $second_id,
        '$id' => '/json_schema/firmware/sku123/2',
        description => 'another hardware schema',
        type => 'firmware',
        name => 'sku123',
        version => 2,
        latest => JSON::PP::true,
        created => ignore,
        created_user => { map +($_ => $ro_user->$_), qw(id name email) },
        deactivated => undef,
      },
    ]);

  $_->get_ok('/hardware_product/'.$hw_id.'/json_schema')
    ->status_is(200)
    ->json_schema_is('HardwareJSONSchemaDescriptions')
    ->json_cmp_deeply([ $main_hardware_description ])
    foreach $t_super, $t_ro, $t_other;

  $t_super->post_ok('/hardware_product/'.$products->[0]{name}.'/json_schema/firmware/sku123/2')
    ->status_is(201)
    ->location_is('/hardware_product/'.$hw_id.'/json_schema');

  $t_ro->get_ok('/hardware_product/'.$hw_id.'/json_schema')
    ->status_is(200)
    ->json_schema_is('HardwareJSONSchemaDescriptions')
    ->json_cmp_deeply([
      $main_hardware_description,
      (my $second_hardware_description = {
        id => $second_id,
        '$id' => '/json_schema/firmware/sku123/2',
        description => 'another hardware schema',
        type => 'firmware',
        name => 'sku123',
        version => 2,
        latest => JSON::PP::true,
        created => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        created_user => { map +($_ => $ro_user->$_), qw(id name email) },
        added => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        added_user => { map +($_ => $super_user->$_), qw(id name email) },
      }),
    ]);

  $t_ro->get_ok('/hardware_product/'.$hw_name.'/json_schema')
    ->status_is(200)
    ->json_schema_is('HardwareJSONSchemaDescriptions')
    ->json_cmp_deeply([
      $main_hardware_description,
      $second_hardware_description,
    ]);

  $t_super->delete_ok('/json_schema/'.$main_id)
    ->status_is(409)
    ->json_schema_is('HardwareProductJSONSchemaDeleteError')
    ->json_is({
      error => 'JSON Schema cannot be deleted: referenced by hardware',
      hardware_product_ids => [ $hw_id ],
    });

  # 'latest' is not supported, due to race conditions (what if someone else added another
  # schema while we are trying to update the hardware associations?)
  $t_super->delete_ok('/hardware_product/'.$products->[0]{name}.'/json_schema/firmware/sku123/latest')
    ->status_is(404)
    ->json_is({ error => 'Route Not Found' });

  $t_super->delete_ok('/hardware_product/'.$products->[0]{name}.'/json_schema/'.create_uuid_str)
    ->status_is(404)
    ->json_is({ error => 'Entity Not Found' })
    ->log_debug_like(qr/^Could not find JSON Schema ${\Conch::UUID::UUID_FORMAT}$/);

  $t_super->delete_ok('/hardware_product/'.$products->[1]{id}.'/json_schema/'.$main_id)
    ->status_is(404)
    ->json_is({ error => 'Entity Not Found' })
    ->log_debug_is('JSON Schema '.$main_id.' is not used by hardware product '.$products->[1]{id});

  $t_ro->delete_ok('/hardware_product/'.$products->[0]{name}.'/json_schema/'.$_)
    ->status_is(403)
    ->log_debug_is('User must be system admin')
      foreach ($main_id, 'firmware/sku123/2');

  $t_super->delete_ok('/hardware_product/'.$products->[0]{name}.'/json_schema/'.$main_id)
    ->status_is(204)
    ->log_debug_is('Removed JSON Schema '.$main_id.' from hardware product '.$products->[0]{name});

  $_->get_ok('/hardware_product/'.$hw_id.'/json_schema')
    ->status_is(200)
    ->json_schema_is('HardwareJSONSchemaDescriptions')
    ->json_cmp_deeply([ $second_hardware_description ])
    foreach $t_super, $t_ro, $t_other;

  $t_super->delete_ok('/hardware_product/'.$products->[0]{name}.'/json_schema/'.$main_id)
    ->status_is(404)
    ->log_debug_is('JSON Schema '.$main_id.' is not used by hardware product '.$products->[0]{name});

  $t_super->delete_ok('/json_schema/'.$main_id)
    ->status_is(204)
    ->log_debug_is('Deactivated JSON Schema id '.$main_id.' (/json_schema/firmware/sku123/1)');

  $t_super->delete_ok('/hardware_product/'.$products->[0]{name}.'/json_schema/firmware/sku123/1')
    ->status_is(410);

  $t_ro->delete_ok('/hardware_product/'.$products->[0]{name}.'/json_schema')
    ->status_is(403)
    ->log_debug_is('User must be system admin');

  $t_super->delete_ok('/hardware_product/'.$products->[0]{name}.'/json_schema')
    ->status_is(204)
    ->log_debug_is('Removed all JSON Schemas from hardware product '.$products->[0]{name});

  $t_super->get_ok('/hardware_product/'.$hw_id.'/json_schema')
    ->status_is(200)
    ->json_schema_is('HardwareJSONSchemaDescriptions')
    ->json_is([]);

  $t_super->delete_ok('/hardware_product/'.$products->[0]{name}.'/json_schema')
    ->status_is(404)
    ->log_debug_is('No JSON Schemas are used by hardware product '.$products->[0]{name});
};

done_testing;
# vim: set sts=2 sw=2 et :
