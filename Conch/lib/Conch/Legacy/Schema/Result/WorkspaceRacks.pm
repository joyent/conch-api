package Conch::Legacy::Schema::Result::WorkspaceRacks;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;
use Conch::Legacy::Schema::Result::DatacenterRack;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('WorkspaceRacks');

#
# Has the same columns as 'DatacenterRack'
__PACKAGE__->add_columns(Conch::Legacy::Schema::Result::DatacenterRack->columns);
#

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

# Note: the subquery on 'workspace_datacenter_rack' should come second in the
# 'OR' clause in order to prevent duplicates. If reveresed with
# `workspace_datacenter_room', query can contain duplicate racks.
__PACKAGE__->result_source_instance->view_definition(q[
  WITH target_workspace (id) AS ( values( ?::uuid ))
  SELECT rack.*
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
]);

__PACKAGE__->belongs_to(
  "role",
  "Conch::Legacy::Schema::Result::DatacenterRackRole",
  { id => "role" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
