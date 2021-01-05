use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Warnings;
use Test::Conch;
use List::Util 'first';

my $t = Test::Conch->new;

my %fixtures = (
    device_location => { rack_unit_start => 3 },
    rack_layouts => [
        { rack_unit_start => 1 },
        { rack_unit_start => 2 },
        { rack_unit_start => 3 },   # redundant with above, but will use the same definition
    ],
);

subtest 'generate_definition' => sub {
    my @definitions = $t->fixtures->generate_definitions(99, %fixtures);

    cmp_deeply(
        \@definitions,
        bag(
            'device_location_99',
            'rack_layout_99_ru1',
            'rack_layout_99_ru2',
            'rack_layout_99_ru3',
            'device_99',
            'rack_99',
            'rack_role_99',
            'datacenter_99',
            'datacenter_room_99',
            'hardware_product_99',
            'hardware_product_99_ru1',
            'hardware_product_99_ru2',
            'hardware_product_99_ru3',
            'hardware_vendor_99',
            'hardware_vendor_99_ru1',
            'hardware_vendor_99_ru2',
            'hardware_vendor_99_ru3',
            'legacy_validation_plan_99',
            'legacy_validation_plan_99_ru1',
            'legacy_validation_plan_99_ru2',
            'legacy_validation_plan_99_ru3',
        ),
        'generated requested fixtures, and for many supporting tables as well',
    );

    # load device_location, which should load all its dependencies as well.
    my $device_location = $t->load_fixture(first { /^device_location_\d+$/ } @definitions);

    is($device_location->device->serial_number, 'DEVICE_99', 'unique string is used in the device serial number');

    isnt(
        $device_location->device->hardware_product_id,
        $device_location->rack_layout->hardware_product_id,
        'device hardware_product is distinct from rack_layout hardware_product',
    );

    is(
        $device_location->rack_layout->rack_id,
        $device_location->rack_id,
        'device_location rack_layout rack_id matches device_location rack_id',
    );
};

subtest 'generate_fixture_definitions wrapper' => sub {
    my @objects = $t->generate_fixtures(%fixtures);
    cmp_deeply(
        \@objects,
        bag(
            map isa('Conch::DB::Result::'.$_), qw(
                DeviceLocation
                RackLayout
                RackLayout
                RackLayout
                Device
                Rack
                RackRole
                Datacenter
                DatacenterRoom
                HardwareProduct
                HardwareProduct
                HardwareProduct
                HardwareProduct
                HardwareVendor
                HardwareVendor
                HardwareVendor
                HardwareVendor
                LegacyValidationPlan
                LegacyValidationPlan
                LegacyValidationPlan
                LegacyValidationPlan
            )
        ),
        'loaded requested fixtures into the database (and for many supporting tables as well)',
    );

    my $device = first { $_->isa('Conch::DB::Result::Device') } @objects;

    is($device->serial_number, 'DEVICE_1000', 'unique string is used in the device serial_number');

    isnt(
        $device->hardware_product_id,
        $device->device_location->rack_layout->hardware_product_id,
        'device hardware_product is distinct from rack_layout hardware_product',
    );

    is(
        $device->device_location->rack_layout->rack_id,
        $device->device_location->rack_id,
        'device_location rack_layout rack_id matches device_location rack_id',
    );
};

subtest 'unnested data' => sub {
    my @objects = $t->generate_fixtures(
        device => {},
        hardware_product => {
            purpose => 'glory',
            hardware_vendor => {
                name => 'Sparta',
            },
        },
    );

    cmp_deeply(
        \@objects,
        bag(
            map isa('Conch::DB::Result::'.$_), qw(
                Device
                HardwareProduct
                HardwareVendor
                LegacyValidationPlan
            )
        ),
        'loaded requested fixtures into the database (and for many supporting tables as well)',
    );

    my $device = first { $_->isa('Conch::DB::Result::Device') } @objects;
    my $hardware_product = first { $_->isa('Conch::DB::Result::HardwareProduct') } @objects;

    is($device->hardware_product_id, $hardware_product->id, 'device joins to hardware_product');
    is($hardware_product->purpose, 'glory', 'got custom hardware_product data');
    is($hardware_product->hardware_vendor->name, 'Sparta', 'got custom vendor data');
};

subtest 'nested data' => sub {
    my @objects = $t->generate_fixtures(
        device => {
            hardware_product => {
                purpose => 'glory',
                hardware_vendor => {
                    name => 'Thebes',
                },
            },
        },
    );

    cmp_deeply(
        \@objects,
        bag(
            map isa('Conch::DB::Result::'.$_), qw(
                Device
                HardwareProduct
                HardwareVendor
                LegacyValidationPlan
            )
        ),
        'loaded requested fixtures into the database (and for many supporting tables as well)',
    );

    my $device = first { $_->isa('Conch::DB::Result::Device') } @objects;
    my $hardware_product = first { $_->isa('Conch::DB::Result::HardwareProduct') } @objects;

    is($device->hardware_product_id, $hardware_product->id, 'device joins to hardware_product');
    is($hardware_product->purpose, 'glory', 'got custom hardware_product data');
    is($hardware_product->hardware_vendor->name, 'Thebes', 'got custom vendor data');
};

subtest 'nested data with layout' => sub {
    my @objects = $t->generate_fixtures(
        device => {
            device_location => {
                rack_unit_start => 3,
                rack_layout => {
                    hardware_product => {
                        name => 'Athens',
                    },
                },
            },
        },
    );

    cmp_deeply(
        \@objects,
        bag(
            map isa('Conch::DB::Result::'.$_), qw(
                Datacenter
                DatacenterRoom
                Device
                DeviceLocation
                HardwareProduct
                HardwareProduct
                HardwareVendor
                HardwareVendor
                Rack
                RackRole
                RackLayout
                LegacyValidationPlan
                LegacyValidationPlan
            )
        ),
        'loaded requested fixtures into the database (and for many supporting tables as well)',
    );

    my $device = first { $_->isa('Conch::DB::Result::Device') } @objects;
    my $layout = first { $_->isa('Conch::DB::Result::RackLayout') } @objects;

    isnt($device->hardware_product_id, $layout->hardware_product_id, 'device gets different hardware than the layout');

    is($device->device_location->rack_unit_start, 3, 'device location is correct');
    is($device->device_location->rack_id, $device->device_location->rack_layout->rack_id, 'device location links to layout rack');
    is($device->device_location->rack_layout->rack_unit_start, 3, 'device location links to layout RU');
};

done_testing;
