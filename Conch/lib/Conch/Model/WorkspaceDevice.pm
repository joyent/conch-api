=pod

=head1 NAME

Conch::Model::WorkspaceDevice

=head1 METHODS

=cut
package Conch::Model::WorkspaceDevice;
use Mojo::Base -base, -signatures;

use Conch::Model::Device;

use Conch::Pg;

=head2 list

List all devices located in workspace.

=cut
sub list ( $self, $ws_id, $last_seen_seconds = undef ) {
	my $last_seen_clause =
		$last_seen_seconds
		? "AND device.last_seen > NOW() - INTERVAL '$last_seen_seconds seconds'"
		: '';

	my $ret = Conch::Pg->new->db->query(
		qq{
		WITH target_workspace (id) AS ( values(?::uuid) )
		SELECT device.*
		FROM device
		JOIN device_location loc
		  ON loc.device_id = device.id
		JOIN datacenter_rack rack
		  ON rack.id = loc.rack_id
		WHERE device.deactivated IS NULL
		  AND (
			rack.datacenter_room_id IN (
			  SELECT datacenter_room_id
			  FROM workspace_datacenter_room
			  WHERE workspace_id = (SELECT id FROM target_workspace)
			)
			OR rack.id IN (
			  SELECT datacenter_rack_id
			  FROM workspace_datacenter_rack
			  WHERE workspace_id = (SELECT id FROM target_workspace)
			)
		  )
  		$last_seen_clause
	}, $ws_id
	)->hashes;

	my @devices;
	for my $d ( $ret->@* ) {
		push @devices, Conch::Model::Device->new(%$d);
	}
	return \@devices;
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

