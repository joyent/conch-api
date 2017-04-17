use utf8;
package Conch::Schema::Result::Device;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Schema::Result::Device

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<device>

=cut

__PACKAGE__->table("device");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  is_nullable: 0
  size: 16

=head2 serial_number

  data_type: 'text'
  is_nullable: 0

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

=head2 deactivated

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

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "serial_number",
  { data_type => "text", is_nullable => 0 },
  "hardware_product",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "state",
  { data_type => "text", is_nullable => 0 },
  "health",
  { data_type => "text", is_nullable => 0 },
  "deactivated",
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
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<device_serial_number_key>

=over 4

=item * L</serial_number>

=back

=cut

__PACKAGE__->add_unique_constraint("device_serial_number_key", ["serial_number"]);

=head1 RELATIONS

=head2 device_disks

Type: has_many

Related object: L<Conch::Schema::Result::DeviceDisk>

=cut

__PACKAGE__->has_many(
  "device_disks",
  "Conch::Schema::Result::DeviceDisk",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_environment

Type: might_have

Related object: L<Conch::Schema::Result::DeviceEnvironment>

=cut

__PACKAGE__->might_have(
  "device_environment",
  "Conch::Schema::Result::DeviceEnvironment",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_location

Type: might_have

Related object: L<Conch::Schema::Result::DeviceLocation>

=cut

__PACKAGE__->might_have(
  "device_location",
  "Conch::Schema::Result::DeviceLocation",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_logs

Type: has_many

Related object: L<Conch::Schema::Result::DeviceLog>

=cut

__PACKAGE__->has_many(
  "device_logs",
  "Conch::Schema::Result::DeviceLog",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_nics

Type: has_many

Related object: L<Conch::Schema::Result::DeviceNic>

=cut

__PACKAGE__->has_many(
  "device_nics",
  "Conch::Schema::Result::DeviceNic",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_notes

Type: has_many

Related object: L<Conch::Schema::Result::DeviceNote>

=cut

__PACKAGE__->has_many(
  "device_notes",
  "Conch::Schema::Result::DeviceNote",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_settings

Type: has_many

Related object: L<Conch::Schema::Result::DeviceSetting>

=cut

__PACKAGE__->has_many(
  "device_settings",
  "Conch::Schema::Result::DeviceSetting",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_spec

Type: might_have

Related object: L<Conch::Schema::Result::DeviceSpec>

=cut

__PACKAGE__->might_have(
  "device_spec",
  "Conch::Schema::Result::DeviceSpec",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_validates

Type: has_many

Related object: L<Conch::Schema::Result::DeviceValidate>

=cut

__PACKAGE__->has_many(
  "device_validates",
  "Conch::Schema::Result::DeviceValidate",
  { "foreign.device_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hardware_product

Type: belongs_to

Related object: L<Conch::Schema::Result::HardwareProduct>

=cut

__PACKAGE__->belongs_to(
  "hardware_product",
  "Conch::Schema::Result::HardwareProduct",
  { id => "hardware_product" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2017-04-17 01:22:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:703ecK5uxrsagqnNytgUjQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
