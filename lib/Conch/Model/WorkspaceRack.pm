=pod

=head1 NAME

Conch::Model::WorkspaceRack

=head1 METHODS

=cut
package Conch::Model::WorkspaceRack;
use Mojo::Base -base, -signatures;

use Conch::Class::DatacenterRack;
use Conch::Pg;

=head2 lookup

Look up a datacenter rack assigned in a workspace.

=cut
sub lookup ( $self, $ws_id, $rack_id ) {
	my $ret = Conch::Pg->new->db->query(
		q{
      WITH target_workspace (id) AS ( values( ?::uuid ))
      SELECT rack.*, role.name AS role_name
      FROM datacenter_rack rack
      JOIN datacenter_rack_role role
        ON rack.datacenter_rack_role_id = role.id
      WHERE rack.id = ?
      AND rack.deactivated is null
      AND (
        rack.datacenter_room_id in (
          SELECT datacenter_room_id
          FROM workspace_datacenter_room
          WHERE workspace_id = (select id from target_workspace)
        )
        OR rack.id in (
          SELECT datacenter_rack_id
          FROM workspace_datacenter_rack
          WHERE workspace_id = (select id from target_workspace)
        )
      )
    }, $ws_id, $rack_id
	)->hash;
	return undef unless $ret;
	return Conch::Class::DatacenterRack->new($ret);
}

=head2 rack_layout

Build a hash representing the layout of the datacenter rack.

=cut
sub rack_layout ( $self, $rack ) {
	my $db = Conch::Pg->new->db;

	my $rack_slots =
		$db->select( 'datacenter_rack_layout', undef, { rack_id => $rack->id } )
		->hashes->to_array;

	my $datacenter_room =
		$db->select( 'datacenter_room', 'az', { id => $rack->datacenter_room_id } )
		->hash;

	my $res;
	$res->{id}         = $rack->id;
	$res->{name}       = $rack->name;
	$res->{role}       = $rack->role_name;
	$res->{datacenter} = $datacenter_room->{az};

	my @slots;

	foreach my $slot (@$rack_slots) {
		my $rack_unit_start = $slot->{rack_unit_start};
		my $hw       = $db->query(
			q{
      SELECT hw.*, vendor.name AS vendor, profile.rack_unit as size
      FROM hardware_product hw
      JOIN hardware_vendor vendor
        ON hw.hardware_vendor_id = vendor.id
      JOIN hardware_product_profile profile
        ON hw.id = profile.hardware_product_id
      WHERE hw.id = ?
      }, $slot->{hardware_product_id}
		)->hash;

		my $device = $db->query(
			q{
      SELECT device.*
      FROM device
      JOIN device_location loc on device.id = loc.device_id
      WHERE loc.rack_id = ?
        AND loc.rack_unit_start = ?
      }, $rack->id, $rack_unit_start
		)->hash;

		my $slot = { rack_unit_start => $rack_unit_start };

		if ($device) {
			$slot->{occupant} = $device;
		}
		else {
			$slot->{occupant} = undef;
		}

		$slot->{id}     = $hw->{id};
		$slot->{alias}  = $hw->{alias};
		$slot->{name}   = $hw->{name};
		$slot->{vendor} = $hw->{vendor};
		$slot->{size}   = $hw->{size};

		push @slots, $slot;
	}

	@slots = sort { $a->{rack_unit_start} <=> $b->{rack_unit_start} } @slots;
	$res->{slots} = \@slots;

	return $res;
}

=head2 list

Retrieve a list of all datacenter racks assigned to a workspace.

=cut
# TODO: This is legacy code. It is overly complicated and hard to test.
# There's too many queries and munging to quickly identify any particular
# problem. -- Lane
sub list ( $self, $ws_id ) {
	my $db = Conch::Pg->new->db;

	my $racks = $db->query(
		q{
    WITH target_workspace (id) AS ( values( ?::uuid ))
    SELECT rack.*
    FROM datacenter_rack rack
    WHERE deactivated is null
      AND (
        rack.datacenter_room_id in (
          SELECT datacenter_room_id
          FROM workspace_datacenter_room
          WHERE workspace_id = (select id from target_workspace)
        )
        OR rack.id in (
          SELECT datacenter_rack_id
          FROM workspace_datacenter_rack
          WHERE workspace_id = (select id from target_workspace)
        )
      )
    }, $ws_id
	)->hashes->to_array;

	my @rack_room_ids = map { $_->{datacenter_room_id} } @$racks;

	my $datacenter_rooms = $db->select( 'datacenter_room', undef,
		{ id => { -in => \@rack_room_ids } } )->hashes->to_array;

	my @rack_ids = map { "'" . $_->{id} . "'" } @$racks;
	my $rack_id_clause =
		scalar @rack_ids ? 'AND rack_id IN (' . join( ',', @rack_ids ) . ')' : '';

	my $rack_progresses = $db->query(
		qq{
      SELECT rack_id, health AS status, count(*) as count
      FROM device
      INNER JOIN device_location
        ON device.id = device_id
      WHERE validated is null
        $rack_id_clause
      GROUP BY rack_id, health

      UNION

      SELECT rack_id, 'VALID' AS status, count(*) as count
      FROM device
      INNER JOIN device_location
        ON device.id = device_id
      WHERE validated is not null
        $rack_id_clause
      GROUP BY rack_id
    }
	)->hashes->to_array;

	my $rack_progress = {};
	for my $rp (@$rack_progresses) {
		$rack_progress->{ $rp->{rack_id} }->{ $rp->{status} } = $rp->{count};
	}

	my $dc;
	foreach my $room (@$datacenter_rooms) {
		$dc->{ $room->{id} }{name} = $room->{az};
	}

	my $all_rack_roles = $db->select('datacenter_rack_role')->hashes->to_array;
	my $rack_roles     = {};
	foreach my $rack_role (@$all_rack_roles) {
		$rack_roles->{ $rack_role->{id} }->{name} = $rack_role->{name};
		$rack_roles->{ $rack_role->{id} }->{size} = $rack_role->{rack_size};
	}

	my $rack_groups = {};
	foreach my $rack (@$racks) {

		my $rack_dc  = $dc->{ $rack->{datacenter_room_id} }{name};
		my $rack_res = {};
		$rack_res->{id}              = $rack->{id};
		$rack_res->{name}            = $rack->{name};
		$rack_res->{role}            = $rack_roles->{ $rack->{datacenter_rack_role_id} }{name};
		$rack_res->{size}            = $rack_roles->{ $rack->{datacenter_rack_role_id} }{size};
		$rack_res->{device_progress} = $rack_progress->{ $rack->{id} } || {};
		push @{ $rack_groups->{$rack_dc} }, $rack_res;
	}
	return $rack_groups;
}

=head2 rack_in_parent_workspace

Determine if a datacenter rack can be assigned to a workspace via a parent
workspace assignment.

=cut
sub rack_in_parent_workspace ( $self, $ws_id, $rack_id ) {
	return Conch::Pg->new->db->query(
		q{
      WITH parent_workspace (id) AS (
        SELECT ws.parent_workspace_id
        FROM workspace ws
        WHERE ws.id = ?::uuid
      )
      SELECT id
      FROM datacenter_rack rack
      WHERE rack.deactivated IS NULL
      AND rack.id = ?
      AND (
        rack.datacenter_room_id IN (
          SELECT datacenter_room_id
          FROM workspace_datacenter_room
          WHERE workspace_id = (SELECT id FROM parent_workspace)
        )
        OR rack.id IN (
          SELECT datacenter_rack_id
          FROM workspace_datacenter_rack wdr
          WHERE workspace_id = (SELECT id FROM parent_workspace)
        )
      )
    }, $ws_id, $rack_id
	)->rows;
}

=head2 rack_in_workspace_room

Determine if a datacenter rack is assigned to a workspace via a datacenter room
assignment.

=cut
sub rack_in_workspace_room ( $self, $ws_id, $rack_id ) {
	return Conch::Pg->new->db->query(
		q{
    SELECT id
    FROM workspace_datacenter_room wdr
    JOIN datacenter_rack rack
    on wdr.datacenter_room_id = rack.datacenter_room_id
    WHERE wdr.workspace_id = ?::uuid
      AND rack.id = ?::uuid
    }, $ws_id, $rack_id
	)->rows;
}

=head2 add_to_workspace

Add a rack to a workspace.

=cut
sub add_to_workspace ( $self, $ws_id, $rack_id ) {
	my $db = Conch::Pg->new->db;

	return undef unless $self->rack_in_parent_workspace( $ws_id, $rack_id );
	return undef if $self->rack_in_workspace_room( $ws_id, $rack_id );

	$db->query(
		q{
    INSERT INTO workspace_datacenter_rack
    (workspace_id, datacenter_rack_id)
    VALUES (?::uuid, ?::uuid)
    ON CONFLICT (workspace_id, datacenter_rack_id) DO NOTHING
    }, $ws_id, $rack_id
	);
	return 1;
}

=head2 remove_from_workspace

Remove a rack from a workspace.

=cut
sub remove_from_workspace ( $self, $ws_id, $rack_id ) {
	my $db = Conch::Pg->new->db;

	my $rack_exists =
		$db->select( 'workspace_datacenter_rack', undef,
		{ workspace_id => $ws_id, datacenter_rack_id => $rack_id } )->rows;

	return undef unless $rack_exists;

	# Remove rack ID from workspace and all children workspaces
	$db->query(
		q{
      WITH RECURSIVE workspace_and_children (id) AS (
          SELECT id
          FROM workspace
          WHERE id = ?::uuid
        UNION
          SELECT w.id
          FROM workspace w, workspace_and_children s
          WHERE w.parent_workspace_id = s.id
      )
      DELETE FROM workspace_datacenter_rack
      WHERE datacenter_rack_id = ?
        AND workspace_id IN (SELECT id FROM workspace_and_children)
    }, $ws_id, $rack_id
	);

	return 1;
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
