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
        my $layout_sku = $location->rack_layout->hardware_product->sku;
        $self->register_result(
            got => $data->{sku},
            expected => $layout_sku,
            message => sprintf('reported sku (%s) should match the sku in the rack layout where the device is located (%s)', $data->{sku}, $layout_sku),
        );
    }

    # also check the device sku itself, which *should* be the same as what the rack_layout
    # says but an earlier version of conch might have changed it.
    my $device_sku = $self->device->hardware_product->sku;
    $self->register_result(
        got      => $data->{sku},
        expected => $device_sku,
        message => sprintf('reported sku (%s) should match the sku assigned to the device (%s)', $data->{sku}, $device_sku),
    );

    # We do not currently define a Conch or Joyent specific name for
    # switches. This may change in the future, but currently we continue
    # to use the vendor product ID.
    if ($data->{device_type} && $data->{device_type} eq "switch") {
        $self->register_result(
            got      => $data->{product_name},
            expected => $self->hardware_product_name,
            message => sprintf('for switch products, reported name (%s) should match the name assigned to the device (%s)', $data->{product_name}, $self->hardware_product_name),
        );
        return;
    }

    # Previous iterations of our hardware naming are still in the field
    # and cannot be updated to the new style. Continue to support them.
    my $message = 'for old server products, reported name (%s) should match the %s assigned to the device (%s)';
    if(
        ($data->{product_name} =~ /^Joyent-Compute/) or
        ($data->{product_name} =~ /^Joyent-Storage/)
    ) {
        $self->register_result(
            got      => $data->{product_name},
            expected => $self->hardware_legacy_product_name,
            message => sprintf($message, $data->{product_name}, 'legacy_product_name', $self->hardware_legacy_product_name),
        );
    } else {
        $self->register_result(
            got      => $data->{product_name},
            expected => $self->hardware_product_generation,
            message => sprintf($message, $data->{product_name}, 'generation_name', $self->hardware_product_generation),
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
