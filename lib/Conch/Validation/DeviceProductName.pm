package Conch::Validation::DeviceProductName;

use Mojo::Base 'Conch::Validation';

use constant name        => 'product_name';
use constant version     => 2;
use constant category    => 'IDENTITY';
use constant description => 'Validate reported product name, sku matches product name, sku expected in rack layout';

sub validate {
    my ($self, $data) = @_;

    # these fields are required in the DeviceReport schema, so we should not ever fail here.
    unless($data->{product_name}) {
        $self->die("Missing 'product_name' property");
    }

    unless($data->{sku}) {
        $self->die("Missing 'sku' property");
    }

    if (my $location = $self->device->device_location) {
        $self->register_result(
            got => $data->{sku},
            expected => $location->rack_layout->hardware_product->sku,
            hint => 'sku in rack layout where the device is located should match the sku reported by the device',
        );
    }

    # We do not currently define a Conch or Joyent specific name for
    # switches. This may change in the future, but currently we continue
    # to use the vendor product ID.
    if ($data->{device_type} && $data->{device_type} eq "switch") {
        $self->register_result(
            expected => $self->hardware_product_name,
            got      => $data->{product_name},
        );
        return;
    }

    # Previous iterations of our hardware naming are still in the field
    # and cannot be updated to the new style. Continue to support them.
    if(
        ($data->{product_name} =~ /^Joyent-Compute/) or
        ($data->{product_name} =~ /^Joyent-Storage/)
    ) {
        $self->register_result(
            expected => $self->hardware_legacy_product_name,
            got      => $data->{product_name},
        );
    } else {
        $self->register_result(
            expected => $self->hardware_product_generation,
            got      => $data->{product_name},
        );
    }
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
