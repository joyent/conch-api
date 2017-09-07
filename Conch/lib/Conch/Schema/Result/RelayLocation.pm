package Conch::Schema::Result::RelayLocation;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table('RelayLocation');

#
# Has the same columns as 'Device'
__PACKAGE__->add_columns(
  "rack_id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "rack_name",
  { data_type => "text", is_nullable => 0 },
  "room_name",
  { data_type => "text", is_nullable => 0 },
  "role_name",
  { data_type => "text", is_nullable => 0 },
);
#

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

# Takes a relay ID and returns the list of devices connected to that relay
__PACKAGE__->result_source_instance->view_definition(q[
  SELECT rack.id as rack_id, rack.name as rack_name,
    room.az as room_name, role.name as role_name
  FROM device_location loc
  JOIN datacenter_rack rack
    ON loc.rack_id = rack.id
  JOIN datacenter_room room
    ON rack.datacenter_room_id = room.id
  JOIN datacenter_rack_role role
    ON rack.role = role.id
  WHERE loc.device_id IN (
    SELECT device_id
    FROM device_relay_connection
    WHERE relay_id = ?
    ORDER BY last_seen desc
    LIMIT 1
  )
]);

1;

