=pod

=head1 NAME

Conch::Model::Device

=head1 METHODS

=cut
package Conch::Model::Device;
use Role::Tiny 'with';
use Mojo::Base -base, -signatures;

use Conch::Time;
use Try::Tiny;
use Data::Validate::UUID qw(is_uuid);

use aliased 'Conch::Class::DatacenterRack';
use aliased 'Conch::Class::DatacenterRoom';
use aliased 'Conch::Class::HardwareProduct';

use Conch::Pg;

has [
	qw(
		asset_tag
		boot_phase
		created
		graduated
		hardware_product
		health
		id
		last_seen
		latest_triton_reboot
		role
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

=head2 as_v1

Serialize a hash according to the v1 schema

=cut
sub as_v1 ($self) {
	{
		asset_tag            => $self->asset_tag,
		boot_phase           => $self->boot_phase,
		created              => $self->created,
		graduated            => $self->graduated,
		hardware_product     => $self->hardware_product,
		health               => $self->health,
		id                   => $self->id,
		last_seen            => $self->last_seen,
		latest_triton_reboot => $self->latest_triton_reboot,
		role                 => $self->role,
		state                => $self->state,
		system_uuid          => $self->system_uuid,
		triton_setup         => $self->triton_setup,
		triton_uuid          => $self->triton_uuid,
		updated              => $self->updated,
		uptime_since         => $self->uptime_since,
		validated            => $self->validated,
	};
}

=head2 create

Create a new device

=cut
sub create (
	$class, $id, $hardware_product_id,
	$state  = 'UNKNOWN',
	$health = 'UNKNOWN'
	)
{
	my $ret;
	try {
		$ret = Conch::Pg->new()->db->insert(
			'device',
			{
				id               => $id,
				hardware_product => $hardware_product_id,
				state            => $state,
				health           => $health
			},
			{ returning => 'id' },
		)->hash;
	};
	return undef unless $ret and $ret->{id};
	return $class->lookup( $ret->{id} );
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

=head2 lookup_for_user

Find a device by ID for a given user, which either:

a) is located in a datacenter rack in one of the user's workspaces
b) has sent a device report proxied by a relay using the user's credentials

=cut
sub lookup_for_user ( $class, $user_id, $device_id ) {
	my $ret = Conch::Pg->new()->db->query(
		q{
		WITH target_workspaces(id) AS (
			SELECT workspace_id
			FROM user_workspace_role
			WHERE user_id = ?
		)
		SELECT distinct device.*
		FROM device
		JOIN device_location loc
			ON loc.device_id = device.id
		JOIN datacenter_rack rack
			ON rack.id = loc.rack_id
		WHERE device.id = ?
		AND device.deactivated IS NULL
		AND (
			rack.datacenter_room_id IN (
				SELECT datacenter_room_id
					FROM workspace_datacenter_room
					WHERE workspace_id IN (SELECT id FROM target_workspaces)
			)
			OR rack.id IN (
				SELECT datacenter_rack_id
				FROM workspace_datacenter_rack
				WHERE workspace_id IN (SELECT id FROM target_workspaces)
			)
		)
	}, $user_id, $device_id
	)->hash;

	unless ( $ret and $ret->{id} ) {
		$ret = Conch::Pg->new()->db->query(
			q{
			SELECT device.*
				FROM user_account u
				INNER JOIN user_relay_connection ur
					ON u.id = ur.user_id
				INNER JOIN device_relay_connection dr
					ON ur.relay_id = dr.relay_id
				INNER JOIN device
					ON dr.device_id = device.id
			WHERE u.id = ?
				AND device.id = ?
				AND device.id NOT IN (SELECT device_id FROM device_location)
		}, $user_id, $device_id
		)->hash;
	}

	return undef unless $ret and $ret->{id};
	return $class->new( $ret->%* );
}

=head2 device_nic_neighbors

Return a hash of NIC and associated NIC peers details for a device

=cut
sub device_nic_neighbors ( $self, $device_id ) {
	my $nics = Conch::Pg->new()->db->query(
		q{
		SELECT nic.*, neighbor.*
		FROM device_nic nic
		JOIN device_neighbor neighbor
			ON nic.mac = neighbor.mac
		WHERE nic.device_id = ?
			AND deactivated IS NULL
	}, $device_id
	)->hashes;

	my @neighbors;
	for my $nic (@$nics) {
		push @neighbors,
			{
			iface_name   => $nic->{iface_name},
			iface_type   => $nic->{iface_type},
			iface_vendor => $nic->{iface_vendor},
			mac          => $nic->{mac},
			peer_mac     => $nic->{peer_mac},
			peer_port    => $nic->{peer_port},
			peer_switch  => $nic->{peer_switch}
			};
	}
	return \@neighbors;
}

=head2 graduate

Mark the device as "graduated" (VLAN flipped) 

=cut
sub graduate ( $self) {
	my $ret = Conch::Pg->new()->db->update(
		'device',
		{
			graduated => 'NOW()',
			updated   => 'NOW()'
		},
		{ id        => $self->id },
		{ returning => [qw(graduated updated)] },
	)->hash;
	return undef unless $ret;

	$self->graduated( Conch::Time->new( $ret->{graduated} ) );
	$self->updated( Conch::Time->new( $ret->{updated} ) );

	return 1;
}

=head2 set_triton_setup

Mark the device as set up for triton.

=cut
sub set_triton_setup ( $self ) {
	my $ret = Conch::Pg->new()->db->update(
		'device',
		{
			triton_setup => 'NOW()',
			updated      => 'NOW()'
		},
		{ id        => $self->id },
		{ returning => [qw(triton_setup updated)] }
	)->hash;
	return undef unless $ret;

	$self->triton_setup( Conch::Time->new($ret->{triton_setup}) );
	$self->updated( Conch::Time->new($ret->{updated}) );
	return 1;
}

=head2 set_triton_uuid

Set and store Triton UUID.

=cut
sub set_triton_uuid ( $self, $uuid ) {
	return undef unless is_uuid($uuid);

	my $ret = Conch::Pg->new()->db->update(
		'device',
		{
			triton_uuid => $uuid,
			updated     => 'NOW()'
		},
		{ id        => $self->id },
		{ returning => [qw(triton_uuid updated)] }
	)->hash;
	return undef unless $ret;

	$self->triton_uuid( $ret->{triton_uuid} );
	$self->updated( $ret->{updated} );
	return 1;
}

=head2 set_triton_reboot

Mark the device as rebooted into Triton.

=cut
sub set_triton_reboot ( $self ) {
	my $ret = Conch::Pg->new()->db->update(
		'device',
		{
			latest_triton_reboot => 'NOW()',
			updated              => 'NOW()'
		},
		{ id        => $self->id },
		{ returning => [qw(latest_triton_reboot updated)] }
	)->hash;
	return undef unless $ret;

	$self->latest_triton_reboot( Conch::Time->new($ret->{latest_triton_reboot}) );
	$self->updated( Conch::Time->new($ret->{updated}) );
	return 1;
}

=head2 set_asset_tag

Set the asset tag for the device

=cut
sub set_asset_tag ( $self, $asset_tag ) {
	my $ret = Conch::Pg->new()->db->update(
		'device',
		{
			asset_tag => $asset_tag,
			updated   => 'NOW()'
		},
		{ id        => $self->id },
		{ returning => [qw(asset_tag updated)] },
	)->hash;
	return undef unless $ret;

	$self->asset_tag( $ret->{asset_tag} );
	$self->updated( $ret->{updated} );
	return 1;
}

=head2 set_validated

Mark the validated timestamp for the device

=cut
sub set_validated ( $self ) {
	my $ret = Conch::Pg->new()->db->update(
		'device',
		{
			validated => 'NOW()',
			updated   => 'NOW()'
		},
		{ id        => $self->id },
		{ returning => [qw(validated updated)] }
	)->hash;
	return undef unless $ret;

	$self->validated( Conch::Time->new($ret->{validated}) );
	$self->updated( Conch::Time->new($ret->{updated}) );
	return 1;
}


=head2 set_role

Sets the C<role> attribute

=cut
sub set_role ( $self, $role ) {
	my $ret = Conch::Pg->new()->db->update(
		'device',
		{
			role    => $role,
			updated => 'NOW()'
		},
		{ id        => $self->id },
		{ returning => [qw(role updated)] },
	)->hash;
	return undef unless $ret;

	$self->role( $ret->{role} );
	$self->updated( $ret->{updated} );
	return 1;
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

