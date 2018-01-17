package Conch::Model::DeviceLocation;
use Mojo::Base -base, -signatures;

use Attempt qw(when_defined attempt fail success);

use aliased 'Conch::Class::DatacenterRack';
use aliased 'Conch::Class::DatacenterRoom';
use aliased 'Conch::Class::DeviceLocation';
use aliased 'Conch::Class::HardwareProduct';

has 'pg';

sub lookup ( $self, $device_id ) {
  when_defined { _build_device_location(shift) } $self->pg->db->query(
    qq{
    SELECT
      loc.rack_unit AS location_rack_unit,

      rack.id           AS rack_id,
      rack.name         AS rack_name,
      rack_role.name    AS rack_role_name,

      room.id           AS room_id,
      room.az           AS room_az,
      room.alias        AS room_alias,
      room.vendor_name  AS room_vendor_name,

      hw_product.id     AS hw_product_id,
      hw_product.name   AS hw_product_name,
      hw_product.alias  AS hw_product_alias,
      hw_product.prefix AS hw_product_prefix,
      hw_product.vendor AS hw_product_vendor

    FROM device_location loc
    JOIN datacenter_rack rack
      ON loc.rack_id = rack.id

    JOIN datacenter_rack_role rack_role
      ON rack.role = rack_role.id

    JOIN datacenter_room room
      ON rack.datacenter_room_id = room.id

    JOIN datacenter_rack_layout layout
      ON layout.rack_id = rack.id AND layout.ru_start = loc.rack_unit

    JOIN hardware_product hw_product
      ON layout.product_id = hw_product.id

    JOIN hardware_vendor vendor
      ON hw_product.vendor = vendor.id

    WHERE loc.device_id = ?
  }, $device_id
  )->hash;
}

sub _build_device_location ($loc) {
  my $datacenter_rack = DatacenterRack->new(
    id        => $loc->{rack_id},
    name      => $loc->{rack_name},
    role_name => $loc->{rack_role_name},
  );
  my $datacenter_room = DatacenterRoom->new(
    id          => $loc->{room_id},
    az          => $loc->{room_az},
    alias       => $loc->{room_alias},
    vendor_name => $loc->{room_vendor_name},
  );
  my $hardware_product = HardwareProduct->new(
    id     => $loc->{hw_product_id},
    name   => $loc->{hw_product_name},
    alias  => $loc->{hw_product_alias},
    prefix => $loc->{hw_product_prefix},
    vendor => $loc->{hw_product_vendor}
  );
  return DeviceLocation->new(
    rack_unit               => $loc->{location_rack_unit},
    datacenter_rack         => $datacenter_rack,
    datacenter_room         => $datacenter_room,
    target_hardware_product => $hardware_product
  );
}

sub assign ( $self, $device_id, $rack_id, $rack_unit ) {
  my $db = $self->pg->db;
  my $tx = $db->begin;

  my $maybe_slot = attempt $db->select(
    'datacenter_rack_layout',
    [ 'id', 'product_id' ],
    { rack_id => $rack_id, ru_start => $rack_unit }
  )->hash;
  return fail("Slot $rack_unit does not exist in the layout for rack $rack_id")
    if $maybe_slot->is_fail;

  my $maybe_occupied = attempt $db->select(
    'device_location',
    ['device_id'],
    {
      rack_id   => $rack_id,
      rack_unit => $rack_unit
    }
  )->hash;

  # Remove current occupant if it exists
  if ( $maybe_occupied->is_success ) {
    $db->delete( 'device_location',
      { device_id => $maybe_occupied->value->{device_id} } );
  }

  my $maybe_device =
    $db->select( 'device', ['id'], { id => $device_id } )->hash;

  # Create a device if it doesn't exist
  unless ($maybe_device) {
    $db->insert(
      'device',
      {
        id               => $device_id,
        health           => "UNKNOWN",
        state            => "UNKNOWN",
        hardware_product => $maybe_slot->value->{product_id},
      }
    );
  }

  $db->query(
    q{
    INSERT INTO device_location (device_id, rack_id, rack_unit)
    VALUES (?, ?, ?)
    ON CONFLICT (device_id) DO UPDATE SET
    rack_id = excluded.rack_id, rack_unit = excluded.rack_unit,
    updated = current_timestamp
  }, $device_id, $rack_id, $rack_unit
  );

  $tx->commit;
  return success;
}

sub unassign ( $self, $device_id ) {
  $self->pg->db->delete( 'device_location', { device_id => $device_id } )->rows;
}

1;
