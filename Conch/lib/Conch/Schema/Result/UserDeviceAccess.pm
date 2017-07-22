package Conch::Schema::Result::UserDeviceAccess;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;
use Conch::Schema::Result::Device;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('UserDeviceAccess');

#
# Has the same columns as 'Device'
__PACKAGE__->add_columns(Conch::Schema::Result::Device->columns);
#

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

# NOTE! This will break if any of the relations between 'user_account' and 'device' change!
# Takes a username and returns the list of devices the user has access to
__PACKAGE__->result_source_instance->view_definition(q[
  SELECT device.*
  FROM user_account u
  INNER JOIN user_datacenter_room_access access
    ON u.id = access.user_id
  INNER JOIN datacenter_room room
    ON access.datacenter_room_id = room.id
  INNER JOIN datacenter_rack rack
    ON room.id = rack.datacenter_room_id
  INNER JOIN device_location loc
    ON rack.id = loc.rack_id
  INNER JOIN device
    ON loc.device_id = device.id
  WHERE u.name = ?
]);
