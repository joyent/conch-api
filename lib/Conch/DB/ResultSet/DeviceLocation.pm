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

=head2 target_hardware_product

Returns a resultset that will produce the 'target_hardware_product' portion of the
DeviceLocation json schema (one hashref per matching device_location).

=cut

sub target_hardware_product ($self) {
    my $me = $self->current_source_alias;
    $self->search(
        {
            'rack_layouts.rack_unit_start' => { '=' => \"$me.rack_unit_start" },
        },
        {
            columns => {
                (map +($_ => 'hardware_product.'.$_), qw(id name alias)),
                vendor => 'hardware_product.hardware_vendor_id',
            },
            join => {
                rack => { rack_layouts => { hardware_product => 'hardware_vendor' } },
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
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
