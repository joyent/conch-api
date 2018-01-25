package Conch::Model::WorkspaceRelay;
use Mojo::Base -base, -signatures;

use Conch::Model::Device;
use aliased 'Conch::Class::WorkspaceRelay';

has 'pg';

sub list ( $self, $ws_id, $interval_minutes = undef ) {
	my $db = $self->pg->db;

	# Find all racks in the workspace
	my $workspace_rack_ids = $db->query(
		q{
      WITH target_workspace (id) AS ( values( ?::uuid ))
      SELECT rack.id
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
	)->hashes->map( sub { $_->{id} } )->to_array;

	return [] unless scalar @$workspace_rack_ids;

	# find relay locations based on the device most recently reported through the
	# relay
	my $relay_locations = $db->query(
		qq{
        SELECT drc1.relay_id, rack.id as rack_id, rack.name as rack_name,
          room.az as room_name, role.name as role_name
        FROM device_relay_connection drc1
        JOIN device d ON
          drc1.device_id = d.id
        JOIN device_location loc ON
          loc.device_id = d.id
        JOIN datacenter_rack rack
          ON loc.rack_id = rack.id
        JOIN datacenter_room room
          ON rack.datacenter_room_id = room.id
        JOIN datacenter_rack_role role
          ON rack.role = role.id
        WHERE rack.id = ANY (?)
        AND drc1.last_seen = (
          SELECT max(drc2.last_seen)
          FROM device_relay_connection drc2
          JOIN device_location loc2
            ON drc2.device_id = loc2.device_id
          WHERE loc.rack_id = loc2.rack_id
        )
      }, $workspace_rack_ids
	)->hashes->to_array;
	return [] unless scalar @$relay_locations;
	my @workspace_relay_ids = map { $_->{relay_id} } @$relay_locations;

	my $interval_clause =
		$interval_minutes
		? "AND updated >= NOW() - INTERVAL '$interval_minutes minutes'"
		: '';
	my $relays = $db->query(
		qq{
      SELECT relay.*
      FROM relay
      WHERE id = ANY (?)
      AND deactivated IS NULL
    }, \@workspace_relay_ids
	)->hashes->to_array;

	my $relay_location_map = {};
	for my $loc (@$relay_locations) {
		$relay_location_map->{ $loc->{relay_id} } = {
			rack_id   => $loc->{rack_id},
			rack_name => $loc->{rack_name},
			room_name => $loc->{room_name},
			role_name => $loc->{role_name}
		};
	}

	my @res;
	for my $relay (@$relays) {
		my $devices = [];
		my $ret     = $db->query(
			qq{
        SELECT device.id
        FROM relay r
        INNER JOIN device_relay_connection dr
          ON r.id = dr.relay_id
        INNER JOIN device
          ON dr.device_id = device.id
        INNER JOIN device_location dl
          ON dl.device_id = device.id
        WHERE r.id = ?
          AND dl.rack_id = ANY (?)
        ORDER by dr.last_seen desc
      }, $relay->{id}, $workspace_rack_ids
		)->hashes;

		for my $d ( $ret->@* ) {
			push $devices->@*, Conch::Model::Device->new( $self->pg, $d->{id} );
		}

		push @res,
			WorkspaceRelay->new(
			id       => $relay->{id},
			alias    => $relay->{alias},
			created  => $relay->{created},
			ipaddr   => $relay->{ipaddr},
			ssh_port => $relay->{ssh_port},
			updated  => $relay->{updated},
			version  => $relay->{version},
			devices  => $devices,
			location => $relay_location_map->{ $relay->{id} }
			);
	}
	return \@res;
}

1;
