package Conch::DB::ResultSet::DeviceLocation;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use experimental 'signatures';

=head1 NAME

Conch::DB::ResultSet::DeviceLocation

=head1 DESCRIPTION

Interface to queries involving device locations.

=head1 METHODS

=head2 assign_device_location

Atomically assign a device to the provided rack and rack unit start position.

- checks that the rack layout exists (dying otherwise)
- removes the current occupant of the location
- makes the location assignment, moving the device if it had a previous location

=cut

sub assign_device_location ($self, $device_id, $rack_id, $rack_unit_start) {
    my $schema = $self->result_source->schema;
    my $layout_rs = $schema->resultset('rack_layout')->search(
        {
            'rack_layout.rack_id' => $rack_id,
            'rack_layout.rack_unit_start' => $rack_unit_start,
        },
        { alias => 'rack_layout' },
    );

    $schema->txn_do(sub {

        die "slot $rack_unit_start does not exist in the layout for rack $rack_id\n"
            if not $layout_rs->exists;

        # create a device if it doesn't exist
        if (not $schema->resultset('device')->search({ id => $device_id })->exists) {
            $schema->resultset('device')->create({
                id      => $device_id,
                hardware_product_id => $layout_rs->get_column('hardware_product_id')->as_query,
                health  => 'unknown',
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

=head2 get_detailed

Returns a resultset that will produce hashref(s) of related location and rack data, matching
the DeviceLocation json schema (one hashref per matching device_location).

=cut

sub get_detailed ($self) {
    my $me = $self->current_source_alias;
    $self->search(
        {
            'rack_layouts.rack_unit_start' => { '=' => \"$me.rack_unit_start" },
        },
        {
            columns => {
                ( map {; "datacenter.$_" => "datacenter_room.$_" } qw(id vendor_name) ),
                'datacenter.name' => 'datacenter_room.az',

                ( map {; "rack.$_" => "rack.$_" } qw(id name) ),
                'rack.unit' => 'device_location.rack_unit_start',
                'rack.role' => 'rack_role.name',

                ( map {; "target_hardware_product.$_" => "hardware_product.$_" } qw(id name alias) ),
                'target_hardware_product.vendor'  => 'hardware_product.hardware_vendor_id',
            },
            join => {
                'rack' => [
                    'rack_role',
                    'datacenter_room',
                    { 'rack_layouts' => { 'hardware_product' => 'hardware_vendor' } },
                ],
            },
        }
    )->hri;
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
