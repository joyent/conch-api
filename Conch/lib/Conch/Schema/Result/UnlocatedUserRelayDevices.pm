package Conch::Schema::Result::UnlocatedUserRelayDevices;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;
use Conch::Schema::Result::Device;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table('UnlocatedUserRelayDevices');

#
# Has the same columns as 'Device'
__PACKAGE__->add_columns(Conch::Schema::Result::Device->columns);
#

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

# Takes a username and returns the list of devices *without a location* they
# have connected to with a relay
__PACKAGE__->result_source_instance->view_definition(q[
  SELECT device.*
  FROM user_account u
  INNER JOIN user_relay_connection ur
    ON u.id = ur.user_id
  INNER JOIN device_relay_connection dr
    ON ur.relay_id = dr.relay_id
  INNER JOIN device
    ON dr.device_id = device.id
  WHERE u.name = ?
    AND device.id NOT IN (SELECT device_id FROM device_location)
]);

