use utf8;
package Conch::Schema::Result::DeviceSpec;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Schema::Result::DeviceSpec

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

=head1 TABLE: C<device_specs>

=cut

__PACKAGE__->table("device_specs");

=head1 ACCESSORS

=head2 device_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 product_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 bios_firmware

  data_type: 'text'
  is_nullable: 0

=head2 hba_firmware

  data_type: 'text'
  is_nullable: 1

=head2 cpu_num

  data_type: 'integer'
  is_nullable: 0

=head2 cpu_type

  data_type: 'text'
  is_nullable: 0

=head2 nics_num

  data_type: 'integer'
  is_nullable: 0

=head2 dimms_num

  data_type: 'integer'
  is_nullable: 0

=head2 ram_total

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "device_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "product_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "bios_firmware",
  { data_type => "text", is_nullable => 0 },
  "hba_firmware",
  { data_type => "text", is_nullable => 1 },
  "cpu_num",
  { data_type => "integer", is_nullable => 0 },
  "cpu_type",
  { data_type => "text", is_nullable => 0 },
  "nics_num",
  { data_type => "integer", is_nullable => 0 },
  "dimms_num",
  { data_type => "integer", is_nullable => 0 },
  "ram_total",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</device_id>

=back

=cut

__PACKAGE__->set_primary_key("device_id");

=head1 RELATIONS

=head2 device

Type: belongs_to

Related object: L<Conch::Schema::Result::Device>

=cut

__PACKAGE__->belongs_to(
  "device",
  "Conch::Schema::Result::Device",
  { id => "device_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 product

Type: belongs_to

Related object: L<Conch::Schema::Result::HardwareProductProfile>

=cut

__PACKAGE__->belongs_to(
  "product",
  "Conch::Schema::Result::HardwareProductProfile",
  { id => "product_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-07-18 10:35:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8RBkT502Ku1td023sleyNw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
