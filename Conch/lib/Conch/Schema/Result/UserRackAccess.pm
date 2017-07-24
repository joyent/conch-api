package Conch::Schema::Result::UserRackAccess;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;
use Conch::Schema::Result::DatacenterRack;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('UserRackAccess');

#
# Has the same columns as 'DatacenterRack'
__PACKAGE__->add_columns(Conch::Schema::Result::DatacenterRack->columns);
#

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(q[
  SELECT rack.*
  FROM user_account u
  INNER JOIN user_datacenter_room_access access
    ON u.id = access.user_id
  INNER JOIN datacenter_room room
    ON access.datacenter_room_id = room.id
  INNER JOIN datacenter_rack rack
    ON room.id = rack.datacenter_room_id
  WHERE u.name = ?
]);
