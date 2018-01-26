package Conch::Legacy::Schema::Result::LatestDeviceReport;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;
use Conch::Legacy::Schema::Result::DeviceReport;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table('LatestDeviceReport');

#
# Has the same columns as 'Device'
__PACKAGE__->add_columns(
  Conch::Legacy::Schema::Result::DeviceReport->columns );
#

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

# Takes a device_id and gives the latest report. Returns at most 1 row.
__PACKAGE__->result_source_instance->view_definition(
  q[
  SELECT me.id, me.device_id, me.report, me.created
  FROM device_report me
  WHERE me.id IN (
    SELECT dr.id FROM device_report dr
    WHERE dr.device_id = ?
    ORDER BY dr.created DESC
    LIMIT 1
  )
]
);

1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

