use utf8;
package Conch::DB::Schema::Result::Device;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Schema::Result::Device

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::Helper::Row::ToJSON>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Helper::Row::ToJSON");

=head1 TABLE: C<device>

=cut

__PACKAGE__->table("device");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_nullable: 0

=head2 system_uuid

  data_type: 'uuid'
  is_nullable: 1
  size: 16

=head2 hardware_product

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 state

  data_type: 'text'
  is_nullable: 0

=head2 health

  data_type: 'text'
  is_nullable: 0

=head2 graduated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 deactivated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 last_seen

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 created

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 updated

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 uptime_since

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 validated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 latest_triton_reboot

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 triton_uuid

  data_type: 'uuid'
  is_nullable: 1
  size: 16

=head2 asset_tag

  data_type: 'text'
  is_nullable: 1

=head2 triton_setup

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 role

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 1
  size: 16

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "text", is_nullable => 0 },
  "system_uuid",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "hardware_product",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "state",
  { data_type => "text", is_nullable => 0 },
  "health",
  { data_type => "text", is_nullable => 0 },
  "graduated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "deactivated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "last_seen",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "created",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "updated",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "uptime_since",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "validated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "latest_triton_reboot",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "triton_uuid",
  { data_type => "uuid", is_nullable => 1, size => 16 },
  "asset_tag",
  { data_type => "text", is_nullable => 1 },
  "triton_setup",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "role",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 1, size => 16 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<device_system_uuid_key>

=over 4

=item * L</system_uuid>

=back

=cut

__PACKAGE__->add_unique_constraint("device_system_uuid_key", ["system_uuid"]);

=head1 RELATIONS

=head2 device_disks

Type: has_many

Related object: L<Conch::DB::Schema::Result::DeviceDisk>

=cut

__PACKAGE__->has_many(
  "device_disks",
  "Conch::DB::Schema::Result::DeviceDisk",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_environment

Type: might_have

Related object: L<Conch::DB::Schema::Result::DeviceEnvironment>

=cut

__PACKAGE__->might_have(
  "device_environment",
  "Conch::DB::Schema::Result::DeviceEnvironment",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_location

Type: might_have

Related object: L<Conch::DB::Schema::Result::DeviceLocation>

=cut

__PACKAGE__->might_have(
  "device_location",
  "Conch::DB::Schema::Result::DeviceLocation",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_logs

Type: has_many

Related object: L<Conch::DB::Schema::Result::DeviceLog>

=cut

__PACKAGE__->has_many(
  "device_logs",
  "Conch::DB::Schema::Result::DeviceLog",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_memories

Type: has_many

Related object: L<Conch::DB::Schema::Result::DeviceMemory>

=cut

__PACKAGE__->has_many(
  "device_memories",
  "Conch::DB::Schema::Result::DeviceMemory",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_nics

Type: has_many

Related object: L<Conch::DB::Schema::Result::DeviceNic>

=cut

__PACKAGE__->has_many(
  "device_nics",
  "Conch::DB::Schema::Result::DeviceNic",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_relay_connections

Type: has_many

Related object: L<Conch::DB::Schema::Result::DeviceRelayConnection>

=cut

__PACKAGE__->has_many(
  "device_relay_connections",
  "Conch::DB::Schema::Result::DeviceRelayConnection",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_reports

Type: has_many

Related object: L<Conch::DB::Schema::Result::DeviceReport>

=cut

__PACKAGE__->has_many(
  "device_reports",
  "Conch::DB::Schema::Result::DeviceReport",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_settings

Type: has_many

Related object: L<Conch::DB::Schema::Result::DeviceSetting>

=cut

__PACKAGE__->has_many(
  "device_settings",
  "Conch::DB::Schema::Result::DeviceSetting",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_spec

Type: might_have

Related object: L<Conch::DB::Schema::Result::DeviceSpec>

=cut

__PACKAGE__->might_have(
  "device_spec",
  "Conch::DB::Schema::Result::DeviceSpec",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_validates

Type: has_many

Related object: L<Conch::DB::Schema::Result::DeviceValidate>

=cut

__PACKAGE__->has_many(
  "device_validates",
  "Conch::DB::Schema::Result::DeviceValidate",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hardware_product

Type: belongs_to

Related object: L<Conch::DB::Schema::Result::HardwareProduct>

=cut

__PACKAGE__->belongs_to(
  "hardware_product",
  "Conch::DB::Schema::Result::HardwareProduct",
  { id => "hardware_product" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 role

Type: belongs_to

Related object: L<Conch::DB::Schema::Result::DeviceRole>

=cut

__PACKAGE__->belongs_to(
  "role",
  "Conch::DB::Schema::Result::DeviceRole",
  { id => "role" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 validation_results

Type: has_many

Related object: L<Conch::DB::Schema::Result::ValidationResult>

=cut

__PACKAGE__->has_many(
  "validation_results",
  "Conch::DB::Schema::Result::ValidationResult",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 validation_states

Type: has_many

Related object: L<Conch::DB::Schema::Result::ValidationState>

=cut

__PACKAGE__->has_many(
  "validation_states",
  "Conch::DB::Schema::Result::ValidationState",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-07-16 11:13:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8Tua36IBT1w15/2coKX5JA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

