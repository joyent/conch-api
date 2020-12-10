package Conch::Validation::TestConchValidationTester;

use Mojo::Base 'Conch::Validation', -signatures;

sub version { 1 }
sub name { 'self tester' }
sub description { 'Test::Conch::Validation tester' }
sub category { 'test' }

use Test::Deep;
use Test::Fatal;
use Conch::UUID;

sub validate ($self, $data) {
    # dispatch to subroutine if provided one
    if (my $subname = $data->{subname}) {
        return $self->$subname($data);
    }
}

sub _has_no_device_location ($self, $data) {
    $self->register_result_cmp_details(
        $self->has_device_location,
        bool(0),
        'no device_location provided -> predicate is false',
    );
    # this generates an error: caller should check predicate first.
    my $location = $self->device_location;
}

sub _has_no_device_settings ($self, $data) {
    $self->register_result_cmp_details(
        $self->device_settings,
        {},
        'no device_location provided -> predicate is false',
    );
}

sub _device_inflation ($self, $data) {
    $self->register_result_cmp_details(
        $self->device,
        all(
            isa('Conch::DB::Result::Device'),
            methods(
                serial_number => $data->{device_serial_number} // re(qr/^DEVICE_\d+$/),
                health => 'unknown',
                hardware_product_id => re(Conch::UUID::UUID_FORMAT),
                in_storage => bool(1),
            ),
        ),
        'device inflated to Conch::DB::Result::Device',
    );
    $self->register_result_cmp_details(
        [ exception { $self->device->update({ asset_tag => 'ohhai' }) } ],
        [ re(qr/permission denied for relation device/) ],
        'cannot modify the device',
    );
}

sub _hardware_product_inflation ($self, $data) {
    $self->register_result_cmp_details(
        $self->hardware_product,
        all(
            isa('Conch::DB::Result::HardwareProduct'),
            methods(
                id => re(Conch::UUID::UUID_FORMAT),
                name => $data->{hardware_product_name} // re(qr/^hardware_product_\d+$/),
                in_storage => bool(1),
            ),
        ),
        'hardware_product is a real result row with a real id',
    );
    $self->register_result_cmp_details(
        [ exception { $self->hardware_product->update({ alias => 'ohhai' }) } ],
        [ re(qr/permission denied for relation hardware_product/) ],
        'cannot modify the hardware_product',
    );

    $self->register_result_cmp_details(
        $self->hardware_product_name,
        $data->{hardware_product_name} // re(qr/^hardware_product_\d+$/),
        'hardware_product name is retrievable',
    );
}

sub _device_location_inflation ($self, $data) {
    $self->register_result_cmp_details(
        $self->has_device_location,
        bool(1),
        'device_location is provided -> predicate is true',
    );
    $self->register_result_cmp_details(
        $self->device_location,
        all(
            isa('Conch::DB::Result::DeviceLocation'),
            methods(
                device_id => re(Conch::UUID::UUID_FORMAT),
                rack_unit_start => $data->{rack_unit_start},
                in_storage => bool(1),
            ),
        ),
        'device_location is a real result row with a real id',
    );
    $self->register_result_cmp_details(
        [ exception { $self->device_location->update({ updated => \'now()' }) } ],
        [ re(qr/permission denied for relation device_location/) ],
        'cannot modify the device_location',
    );
}

sub _rack_layout_different_hardware_product ($self, $data) {
    $self->register_result_cmp_details(
        $self->device->device_location->rack_layout->hardware_product_id,
        none($self->device->hardware_product_id),
        'rack layout gets a different hardware product than the device',
    );
}

sub _rack_inflation ($self, $data) {
    $self->register_result_cmp_details(
        $self->device_location->rack,
        all(
            isa('Conch::DB::Result::Rack'),
            methods(
                id => re(Conch::UUID::UUID_FORMAT),
                name => $data->{rack_name} // re(qr/^rack_\d+$/),
                in_storage => bool(1),
            ),
        ),
        'real rack row created when requested',
    );
    $self->register_result_cmp_details(
        [ exception { $self->device_location->rack->update({ name => 'ohhai' }) } ],
        [ re(qr/permission denied for relation rack/) ],
        'cannot modify the rack',
    );
}

sub _device_settings_storage ($self, $data) {
    $self->register_result_cmp_details(
        $self->device_settings,
        { foo => 'bar' },
        'device_settings are retrievable',
    );
}

1;
# vim: set sts=2 sw=2 et :
