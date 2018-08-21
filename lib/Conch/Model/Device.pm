=pod

=head1 NAME

Conch::Model::Device

=head1 METHODS

=cut
package Conch::Model::Device;
use Role::Tiny 'with';
use Mojo::Base -base, -signatures;

use Conch::Time;
use Conch::UUID qw(is_uuid);

use Conch::Pg;

has [
	qw(
		asset_tag
		created
		graduated
		hardware_product_id
		health
		hostname
		id
		last_seen
		latest_triton_reboot
		state
		system_uuid
		triton_setup
		triton_uuid
		updated
		uptime_since
		validated
		)
];

=head2 new

=cut
sub new ( $class, %args ) {
	map { $args{$_} = Conch::Time->new( $args{$_} ) if $args{$_} }
		qw(created graduated last_seen latest_triton_reboot triton_setup updated uptime_since validated);
	$class->SUPER::new(%args);
}

=head2 TO_JSON

Serialize a hash

=cut
sub TO_JSON ($self) {
	{
		asset_tag            => $self->asset_tag,
		created              => $self->created,
		graduated            => $self->graduated,
		hardware_product     => $self->hardware_product_id,     # XXX special
		health               => $self->health,
		hostname             => $self->hostname,
		id                   => $self->id,
		last_seen            => $self->last_seen,
		latest_triton_reboot => $self->latest_triton_reboot,
		state                => $self->state,
		system_uuid          => $self->system_uuid,
		triton_setup         => $self->triton_setup,
		triton_uuid          => $self->triton_uuid,
		updated              => $self->updated,
		uptime_since         => $self->uptime_since,
		validated            => $self->validated,
		# XXX no 'deactivated'
	};
}

=head2 lookup

Find a device by ID (sometimes also called "serial number") or return undef.
Does not consider user access restrictions.

=cut
sub lookup ( $class, $device_id ) {
	my $ret = Conch::Pg->new()->db->select(
		'device', undef,
		{
			id          => $device_id,
			deactivated => undef
		}
	)->hash;
	return undef unless $ret and $ret->{id};
	return $class->new( $ret->%* );
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
