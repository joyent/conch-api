package Conch::Validation::TestConchValidationTester;

use Mojo::Base 'Conch::Validation', -signatures;

sub version { 1 }
sub name { 'self tester' }
sub description { 'Test::Conch::Validation tester' }
sub category { 'test' }

use Conch::UUID 'create_uuid_str';
use Test::Deep;
use Test::Fatal;

sub validate ($self, $data) {
    # dispatch to subroutine if provided one
    if (my $subname = $data->{subname}) {
        return $self->$subname($data);
    }
}

sub _has_no_hardware_product_profile ($self, $data) {
    $self->register_result_cmp_details(
        $self->hardware_product_profile,
        undef,
        'no hardware_product_profile data requested -> not populated into the db',
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
            isa('Conch::DB::Result::Device'),
            methods(
                id => $data->{device_id} // re(qr/^DEVICE_\d+$/),
                state => 'UNKNOWN',
                health => 'unknown',
                hardware_product_id => re(Conch::UUID::UUID_FORMAT),
                in_storage => bool(1),
            ),
        ),
        'device inflated to Conch::DB::Result::Device',
    );
    $self->register_result_cmp_details(
        [ exception { $self->device->update({ asset_tag => 'ohhai' }) } ],
        [ re(qr/cannot execute UPDATE in a read-only transaction/) ],
        'cannot modify the device',
    );
    $self->device->result_source->schema->txn_rollback;
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
        [ re(qr/cannot execute UPDATE in a read-only transaction/) ],
        'cannot modify the hardware_product',
    );
    $self->hardware_product->result_source->schema->txn_rollback;

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
            isa('Conch::DB::Result::HardwareProductProfile'),
            $self->hardware_product->hardware_product_profile,
            methods(
                id => re(Conch::UUID::UUID_FORMAT),
                $data->{hardware_product_profile_dimms_num} ? ( dimms_num => $data->{hardware_product_profile_dimms_num} ) : (),
                in_storage => bool(1),
            ),
        ),
        'hardware_product_profile is a real result row with a real id, joined to hardware_product',
    );
    $self->register_result_cmp_details(
        [ exception { $self->hardware_product_profile->update({ purpose => 'ohhai' }) } ],
        [ re(qr/cannot execute UPDATE in a read-only transaction/) ],
        'cannot modify the hardware_product_profile',
    );
    $self->hardware_product_profile->result_source->schema->txn_rollback;
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
                device_id => $data->{device_id} // re(qr/^DEVICE_\d+$/),
                rack_unit_start => $data->{rack_unit_start},
                in_storage => bool(1),
            ),
        ),
        'device_location is a real result row with a real id',
    );
    $self->register_result_cmp_details(
        [ exception { $self->device_location->update({ updated => \'now()' }) } ],
        [ re(qr/cannot execute UPDATE in a read-only transaction/) ],
        'cannot modify the device_location',
    );
    $self->device_location->result_source->schema->txn_rollback;
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
        [ re(qr/cannot execute UPDATE in a read-only transaction/) ],
        'cannot modify the rack',
    );
    $self->device_location->rack->result_source->schema->txn_rollback;
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
