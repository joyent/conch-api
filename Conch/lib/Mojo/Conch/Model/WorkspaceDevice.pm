package Mojo::Conch::Model::WorkspaceDevice;
use Mojo::Base -base, -signatures;

use Attempt 'when_defined';
use aliased 'Mojo::Conch::Class::Device';

has 'pg';

sub list ( $self, $ws_id, $last_seen_seconds = undef ) {
  my $last_seen_clause = $last_seen_seconds ?
    "AND device.last_seen > NOW() - INTERVAL '$last_seen_seconds seconds'"
    : '';
  $self->pg->db->query(qq{
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
  }, $ws_id)->hashes->map( sub { Device->new(shift) })->to_array;
}

1;

