package Conch::DB::ResultSet::DeviceLocation;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

=head1 NAME

Conch::DB::ResultSet::DeviceLocation

=head1 DESCRIPTION

Interface to queries involving device locations.

=head1 METHODS

=head2 assign_device_location

Atomically assign a device to the provided datacenter rack and rack unit start position.

- checks that the rack layout exists (dying otherwise)
- removes the current occupant of the location
- makes the location assignment, moving the device if it had a previous location

=cut

sub assign_device_location {
    my ($self, $device_id, $rack_id, $rack_unit_start) = @_;

    my $schema = $self->result_source->schema;
    my $layout_rs = $schema->resultset('datacenter_rack_layout')->search(
        {
            'datacenter_rack_layout.rack_id' => $rack_id,
            'datacenter_rack_layout.rack_unit_start' => $rack_unit_start,
        },
        { alias => 'datacenter_rack_layout' },
    );

    $schema->txn_do(sub {

        die "slot $rack_unit_start does not exist in the layout for rack $rack_id\n"
            if not $layout_rs->exists;

        # create a device if it doesn't exist
        if (not $schema->resultset('device')->search({ id => $device_id })->exists) {
            $schema->resultset('device')->create({
                id      => $device_id,
                hardware_product_id => $layout_rs->get_column('hardware_product_id')->as_query,
                health  => 'UNKNOWN',
                state   => 'UNKNOWN',
            });
        }

        # remove current occupant if it exists
        my $device_location_rs = $layout_rs->related_resultset('device_location');
        $device_location_rs->delete if $device_location_rs->exists;

        # create device_location entry, moving the device's location if it already had one
        $self->update_or_create(
            {
                device_id => $device_id,
                rack_id => $rack_id,
                rack_unit_start => $rack_unit_start,
                updated => \'now()',
            },
            { key => 'primary' },
        );
    });
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
# vim: set ts=4 sts=4 sw=4 et :
