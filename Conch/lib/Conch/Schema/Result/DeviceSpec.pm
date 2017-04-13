use utf8;
package Conch::Schema::Result::DeviceSpec;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Schema::Result::DeviceSpec

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

=head1 TABLE: C<device_specs>

=cut

__PACKAGE__->table("device_specs");

=head1 ACCESSORS

=head2 device_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

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

=head2 dimms_num

  data_type: 'integer'
  is_nullable: 0

=head2 ram_total

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "device_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
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


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2017-04-13 05:24:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0+n0q5zptNQujV31h4HSKw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
