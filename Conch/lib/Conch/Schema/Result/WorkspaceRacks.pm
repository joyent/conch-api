package Conch::Schema::Result::WorkspaceRacks;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;
use Conch::Schema::Result::DatacenterRack;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('WorkspaceRacks');

#
# Has the same columns as 'DatacenterRack'
__PACKAGE__->add_columns(Conch::Schema::Result::DatacenterRack->columns);
#

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(q[
  SELECT rack.*
  FROM workspace_datacenter_room wdr
  JOIN datacenter_rack rack
    ON wdr.datacenter_room_id = rack.datacenter_room_id
  WHERE wdr.workspace_id = ?
    AND rack.deactivated is null
]);

__PACKAGE__->belongs_to(
  "role",
  "Conch::Schema::Result::DatacenterRackRole",
  { id => "role" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

1;
