package Conch::Schema::Result::RelayLocation;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table('RelayLocation');

#
# Has the same columns as 'Device'
__PACKAGE__->add_columns(
  "relay_id",
  { data_type => "text", is_nullable => 0 },
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

# For all relays, give the *exclusive* rack location based on the most recent
# timestamp for any devices connected to the rack.
#
# Example: PRD1 connects to device A in rack 1. PRD1 is removed and PRD2
# connects to Device B which also happens to be in rack 1. This query should
# show that PRD2 is connected to rack 1 and PRD 1 is not.
#
__PACKAGE__->result_source_instance->view_definition(q[
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
  WHERE drc1.last_seen = (
    SELECT max(drc2.last_seen)
    FROM device_relay_connection drc2
    JOIN device_location loc2
      ON drc2.device_id = loc2.device_id
    WHERE loc.rack_id = loc2.rack_id
  )
]);

1;

