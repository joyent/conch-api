=pod

=head1 NAME

Conch::Class::DeviceLocation

=head1 METHODS

=cut

package Conch::Class::DeviceLocation;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::JsonV1';



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


=head2 TO_JSON

=cut

sub TO_JSON {
	my $self = shift;
	return {
		datacenter => {
			id          => $self->datacenter_room->id,
			name        => $self->datacenter_room->az,
			vendor_name => $self->datacenter_room->vendor_name,
		},
		rack => {
			id   => $self->datacenter_rack->id,
			unit => $self->rack_unit,
			name => $self->datacenter_rack->name,
			role => $self->datacenter_rack->role_name,
		},
		target_hardware_product => {
			id     => $self->target_hardware_product->id,
			name   => $self->target_hardware_product->name,
			alias  => $self->target_hardware_product->alias,
			vendor => $self->target_hardware_product->vendor,
		},
	};
}

1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
