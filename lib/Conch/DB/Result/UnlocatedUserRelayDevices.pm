package Conch::DB::Result::UnlocatedUserRelayDevices;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;
use Conch::DB::Result::Device;

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table('UnlocatedUserRelayDevices');

#
# Has the same columns as 'Device'
__PACKAGE__->add_columns( Conch::DB::Result::Device->columns );
#

# do not attempt to deploy() this view
__PACKAGE__->result_source_instance->is_virtual(1);

# Takes a username and returns the list of devices *without a location* they
# have connected with a relay
__PACKAGE__->result_source_instance->view_definition(
  q[
  SELECT device.*
  FROM user_account u
  INNER JOIN user_relay_connection ur
    ON u.id = ur.user_id
  INNER JOIN device_relay_connection dr
    ON ur.relay_id = dr.relay_id
  INNER JOIN device
    ON dr.device_id = device.id
  WHERE u.id = ?
    AND device.id NOT IN (SELECT device_id FROM device_location)
]
);

# NOTE: UPDATE BELOW WHEN Conch::Result::Device IS UPDATED!

=head1 RELATIONS

=head2 device_disks

Type: has_many

Related object: L<Conch::DB::Result::DeviceDisk>

=cut

__PACKAGE__->has_many(
  "device_disks",
  "Conch::DB::Result::DeviceDisk",
  { "foreign.device_id" => "self.id" },
  { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 device_environment

Type: might_have

Related object: L<Conch::DB::Result::DeviceEnvironment>

=cut

__PACKAGE__->might_have(
  "device_environment",
  "Conch::DB::Result::DeviceEnvironment",
  { "foreign.device_id" => "self.id" },
  { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 device_location

Type: might_have

Related object: L<Conch::DB::Result::DeviceLocation>

=cut

__PACKAGE__->might_have(
  "device_location",
  "Conch::DB::Result::DeviceLocation",
  { "foreign.device_id" => "self.id" },
  { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 device_logs

Type: has_many

Related object: L<Conch::DB::Result::DeviceLog>

=cut

__PACKAGE__->has_many(
  "device_logs",
  "Conch::DB::Result::DeviceLog",
  { "foreign.device_id" => "self.id" },
  { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 device_memories

Type: has_many

Related object: L<Conch::DB::Result::DeviceMemory>

=cut

__PACKAGE__->has_many(
  "device_memories",
  "Conch::DB::Result::DeviceMemory",
  { "foreign.device_id" => "self.id" },
  { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 device_nics

Type: has_many

Related object: L<Conch::DB::Result::DeviceNic>

=cut

__PACKAGE__->has_many(
  "device_nics",
  "Conch::DB::Result::DeviceNic",
  { "foreign.device_id" => "self.id" },
  { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 device_notes

Type: has_many

Related object: L<Conch::DB::Result::DeviceNote>

=cut

__PACKAGE__->has_many(
  "device_notes",
  "Conch::DB::Result::DeviceNote",
  { "foreign.device_id" => "self.id" },
  { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 device_relay_connections

Type: has_many

Related object: L<Conch::DB::Result::DeviceRelayConnection>

=cut

__PACKAGE__->has_many(
  "device_relay_connections",
  "Conch::DB::Result::DeviceRelayConnection",
  { "foreign.device_id" => "self.id" },
  { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 device_reports

Type: has_many

Related object: L<Conch::DB::Result::DeviceReport>

=cut

__PACKAGE__->has_many(
  "device_reports",
  "Conch::DB::Result::DeviceReport",
  { "foreign.device_id" => "self.id" },
  { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 device_settings

Type: has_many

Related object: L<Conch::DB::Result::DeviceSetting>

=cut

__PACKAGE__->has_many(
  "device_settings",
  "Conch::DB::Result::DeviceSetting",
  { "foreign.device_id" => "self.id" },
  { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 device_spec

Type: might_have

Related object: L<Conch::DB::Result::DeviceSpec>

=cut

__PACKAGE__->might_have(
  "device_spec",
  "Conch::DB::Result::DeviceSpec",
  { "foreign.device_id" => "self.id" },
  { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 device_validates

Type: has_many

Related object: L<Conch::DB::Result::DeviceValidate>

=cut

__PACKAGE__->has_many(
  "device_validates",
  "Conch::DB::Result::DeviceValidate",
  { "foreign.device_id" => "self.id" },
  { cascade_copy        => 0, cascade_delete => 0 },
);

=head2 hardware_product

Type: belongs_to

Related object: L<Conch::DB::Result::HardwareProduct>

=cut

__PACKAGE__->belongs_to(
  "hardware_product",
  "Conch::DB::Result::HardwareProduct",
  { id            => "hardware_product" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 triton

Type: might_have

Related object: L<Conch::DB::Result::Triton>

=cut

__PACKAGE__->might_have(
  "triton",
  "Conch::DB::Result::Triton",
  { "foreign.id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
