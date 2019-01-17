package Conch::Validation::TestConchValidationTester;

use Mojo::Base 'Conch::Validation', -signatures;

sub version { 1 }
sub name { 'self tester' }
sub description { 'Test::Conch::Validation tester' }
sub category { 'test' }

use Conch::UUID;
use Test::Deep;

sub validate ($self, $data) {
    # dispatch to subroutine if provided one
    if (my $subname = $data->{subname}) {
        return $self->$subname($data);
    }
}

sub _has_no_device ($self, $data) {
    # this throws an exception
    my $device = $self->device;
}

sub _has_no_hardware_product ($self, $data) {
    $self->register_result_cmp_details(
        $self->{_hardware_product},
        undef,
        'no hardware_product provided',
    );
    # this generates an error: hardware_product should always be provided
    my $product_name = $self->hardware_product_name;
}

sub _has_no_hardware_product_profile ($self, $data) {
    $self->register_result_cmp_details(
        $self->hardware_product_profile,
        undef,
        'no hardware_product means no hardware_product_profile',
    );
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
            isa('Conch::Model::Device'),
            methods(
                id => $data->{device_id} // re(qr/^DEVICE_\d+$/),
                state => 'UNKNOWN',
                health => 'UNKNOWN',
                hardware_product_id => re(Conch::UUID::UUID_FORMAT),
            ),
        ),
        'device inflated to Conch::Model::Device, with a real hardware_product_id',
    );
}

sub _hardware_product_inflation ($self, $data) {
    $self->register_result_cmp_details(
        $self->{_hardware_product},
        all(
            isa('Conch::Class::HardwareProduct'),
            methods(
                id => re(Conch::UUID::UUID_FORMAT),
                name => $data->{hardware_product_name} // re(qr/^hardware_product_\d+$/),
            ),
        ),
        'hardware_product inflated to Conch::Class::HardwareProduct with a real id',
    );
    $self->register_result_cmp_details(
        $self->hardware_product_name,
        $data->{hardware_product_name} // re(qr/^hardware_product_\d+$/),
        'hardware_product name is retrievable',
    );
}

sub _hardware_product_profile_inflation ($self, $data) {
    $self->register_result_cmp_details(
        $self->hardware_product_profile,
        all(
            isa('Conch::Class::HardwareProductProfile'),
            $self->{_hardware_product}->profile,
            methods(
                id => re(Conch::UUID::UUID_FORMAT),
                $data->{hardware_product_profile_rack_unit} ? ( rack_unit => $data->{hardware_product_profile_rack_unit} ) : (),
            ),
        ),
        'profile inflated to Conch::Class::HardwareProductProfile with a real id, joined to hardware_product',
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
            isa('Conch::Class::DeviceLocation'),
            methods(
                rack_unit => $data->{rack_unit_start},
                datacenter_rack => isa('Conch::Class::DatacenterRack'),
                datacenter_room => isa('Conch::Class::DatacenterRoom'),
                target_hardware_product => isa('Conch::Class::HardwareProduct'),
            ),
        ),
        'device_location inflated to Conch::Model::DeviceLocation with real data and related rows',
    );
}

sub _datacenter_rack_inflation ($self, $data) {
    $self->register_result_cmp_details(
        $self->device_location->datacenter_rack,
        all(
            isa('Conch::Class::DatacenterRack'),
            methods(
                id => re(Conch::UUID::UUID_FORMAT),
                name => $data->{datacenter_rack_name} // re(qr/^datacenter_rack_\d+$/),
                slots => [ $data->{rack_unit_start} ],
            ),
        ),
        'real datacenter_rack row created when requested',
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
# vim: set ts=4 sts=4 sw=4 et :
