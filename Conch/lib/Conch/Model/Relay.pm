package Conch::Model::Relay;
use Mojo::Base -base, -signatures;

use Attempt qw(attempt try);

has 'pg';

sub create ( $self, $serial, $version, $ipaddr, $ssh_port, $alias,
  $ip_origin = undef )
{
  try {
    $self->pg->db->query(
      q{
      INSERT INTO relay
        ( id, version, ipaddr, ssh_port, updated )
      VALUES
        ( ?, ?, ?, ?, ? )
      ON CONFLICT (id) DO UPDATE
      SET id = excluded.id,
          version = excluded.version,
          ipaddr = excluded.ipaddr,
          ssh_port = excluded.ssh_port,
          updated = excluded.updated
    },
      $serial,
      $version,
      $ipaddr,
      $ssh_port,
      'NOW()'
      )->rows
  };
}

sub lookup ( $self, $relay_id ) {
  attempt $self->pg->db->select( 'relay', undef, { id => $relay_id } )->hash;
}

# Associate relay with a user
sub connect_user_relay ( $self, $user_id, $relay_id ) {
  try {
    # 'first_seen' column will only be written on create. It should remain
    # unchanged on updates
    $self->pg->db->query(
      q{
        INSERT INTO user_relay_connection
          ( user_id, relay_id, last_seen )
        VALUES
          ( ?, ?, ? )
        ON CONFLICT (user_id, relay_id) DO UPDATE
        SET user_id = excluded.user_id,
            relay_id = excluded.relay_id,
            last_seen = excluded.last_seen
      }, $user_id, $relay_id, 'NOW()'
    )->rows;
  };
}

# Associate relay with a device
sub connect_device_relay ( $self, $device_id, $relay_id ) {
  try {
    # 'first_seen' column will only be written on create. It should remain
    # unchanged on updates
    $self->pg->db->query(
      q{
        INSERT INTO device_relay_connection
          ( device_id, relay_id, last_seen )
        VALUES
          ( ?, ?, ? )
        ON CONFLICT (device_id, relay_id) DO UPDATE
        SET device_id = excluded.device_id,
            relay_id = excluded.relay_id,
            last_seen = excluded.last_seen
      }, $device_id, $relay_id, 'NOW()'
    )->rows;
  };
}

1;
