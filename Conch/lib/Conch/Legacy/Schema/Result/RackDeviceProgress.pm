package Conch::Legacy::Schema::Result::RackDeviceProgress;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

# For the time being this is necessary even for virtual views
__PACKAGE__->table('RackDeviceProgress');

# Has the same columns as 'Device'
__PACKAGE__->add_columns(

  "rack_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "status",
  { data_type => "text", is_nullable => 0 },
  "count",
  { data_type => "int", is_nullable => 0 },
);

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(q[
  SELECT rack_id, health AS status, count(*) as count
  FROM device
  INNER JOIN device_location
    ON device.id = device_id
  WHERE validated is null
  GROUP BY rack_id, health

  UNION

  SELECT rack_id, 'VALID' AS status, count(*) as count
  FROM device
  INNER JOIN device_location
    ON device.id = device_id
  WHERE validated is not null
  GROUP BY rack_id
]);

1;
