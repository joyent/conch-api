package Mojo::Conch::Model::Device;
use Mojo::Base -base, -signatures;

use Attempt qw(try fail success attempt when_defined);

use aliased 'Mojo::Conch::Class::Device';

has 'pg';

sub create ($self, $id, $hardware_product_id, $state = 'UNKNOWN', $health = 'UNKNOWN') {
  my $create_attempt = try {
    $self->pg->db->insert('device', {
        id               => $id,
        hardware_product => $hardware_product_id,
        state            => $state,
        health           => $health
      }, { returning => ['id'] } )->hash;
  };
  $create_attempt->next(sub { shift->{id} });
}

sub lookup ($self, $device_id) {
  when_defined { Device->new(shift) } $self->pg->db->select('device', undef, { 
      id => $device_id,
      deactivated => undef
  })->hash;
}

sub lookup_for_user ($self, $user_id, $device_id) {
  my $db = $self->pg->db;
  my $maybe_device = _lookup_device_in_user_workspaces($db, $user_id, $device_id);

  # Look for an unlocated device if no located device found
  $maybe_device = $maybe_device ||
    _lookup_unlocated_device_reported_by_user_relay($db, $user_id, $device_id);
  return $maybe_device->next( sub { Device->new(shift) });

}

sub device_nic_neighbors ($self, $device_id) {
  my $nics = $self->pg->db->query(q{
      SELECT nic.*, neighbor.*
      FROM device_nic nic
      JOIN device_neighbor neighbor
        ON nic.mac = neighbor.mac
      WHERE nic.device_id = ?
        AND deactivated IS NULL
    }, $device_id )->hashes;
  my @neighbors;
  for my $nic (@$nics) {
    push @neighbors, {
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

sub _lookup_device_in_user_workspaces ($db, $user_id, $device_id) {
  attempt $db->query(q{
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
  }, $user_id, $device_id )->hash;
}

sub _lookup_unlocated_device_reported_by_user_relay ($db, $user_id, $device_id) {
  attempt $db->query(q{
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
  }, $user_id, $device_id )->hash;
}

sub graduate_device ($self, $device_id) {
  $self->pg->db->update(
    'device', { graduated => 'NOW()', updated => 'NOW()' },
    { id => $device_id }
  );
}

sub set_triton_setup ($self, $device_id) {
  $self->pg->db->update(
    'device', { triton_setup => 'NOW()', updated => 'NOW()' },
    { id => $device_id }
  );
}

sub set_triton_uuid ($self, $device_id, $uuid) {
  $self->pg->db->update(
    'device', { triton_uuid => $uuid, updated => 'NOW()' },
    { id => $device_id }
  );
}

sub set_triton_reboot ($self, $device_id) {
  $self->pg->db->update(
    'device', { latest_triton_reboot => 'NOW()', updated => 'NOW()' },
    { id => $device_id }
  );
}

sub set_asset_tag ($self, $device_id, $asset_tag) {
  $self->pg->db->update(
    'device', { asset_tag => $asset_tag, updated => 'NOW()' },
    { id => $device_id }
  );
}


1;
