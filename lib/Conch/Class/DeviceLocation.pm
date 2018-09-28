=pod

=head1 NAME

Conch::Class::DeviceLocation

=head1 METHODS

=cut

package Conch::Class::DeviceLocation;
use Mojo::Base -base, -signatures;


=head2 rack_unit

=head2 datacenter_rack

=head2 datacenter_room

=head2 target_hardware_product

=cut

has [
	qw(
		rack_unit
		datacenter_rack
		datacenter_room
		target_hardware_product
		)
];

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
