use utf8;
package Conch::Schema::Result::HardwareProductProfile;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Schema::Result::HardwareProductProfile

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

=head1 TABLE: C<hardware_product_profile>

=cut

__PACKAGE__->table("hardware_product_profile");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: gen_random_uuid()
  is_nullable: 0
  size: 16

=head2 product_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 purpose

  data_type: 'text'
  is_nullable: 0

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

=head2 nics_num

  data_type: 'integer'
  is_nullable: 0

=head2 sata_num

  data_type: 'integer'
  is_nullable: 1

=head2 sata_size

  data_type: 'integer'
  is_nullable: 1

=head2 sata_slots

  data_type: 'text'
  is_nullable: 1

=head2 sas_num

  data_type: 'integer'
  is_nullable: 1

=head2 sas_size

  data_type: 'integer'
  is_nullable: 1

=head2 sas_slots

  data_type: 'text'
  is_nullable: 1

=head2 ssd_num

  data_type: 'integer'
  is_nullable: 1

=head2 ssd_size

  data_type: 'integer'
  is_nullable: 1

=head2 ssd_slots

  data_type: 'text'
  is_nullable: 1

=head2 psu_total

  data_type: 'integer'
  is_nullable: 1

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
  {
    data_type => "uuid",
    default_value => \"gen_random_uuid()",
    is_nullable => 0,
    size => 16,
  },
  "product_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "purpose",
  { data_type => "text", is_nullable => 0 },
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
  "nics_num",
  { data_type => "integer", is_nullable => 0 },
  "sata_num",
  { data_type => "integer", is_nullable => 1 },
  "sata_size",
  { data_type => "integer", is_nullable => 1 },
  "sata_slots",
  { data_type => "text", is_nullable => 1 },
  "sas_num",
  { data_type => "integer", is_nullable => 1 },
  "sas_size",
  { data_type => "integer", is_nullable => 1 },
  "sas_slots",
  { data_type => "text", is_nullable => 1 },
  "ssd_num",
  { data_type => "integer", is_nullable => 1 },
  "ssd_size",
  { data_type => "integer", is_nullable => 1 },
  "ssd_slots",
  { data_type => "text", is_nullable => 1 },
  "psu_total",
  { data_type => "integer", is_nullable => 1 },
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

=head2 C<hardware_product_profile_product_id_key>

=over 4

=item * L</product_id>

=back

=cut

__PACKAGE__->add_unique_constraint("hardware_product_profile_product_id_key", ["product_id"]);

=head1 RELATIONS

=head2 device_specs

Type: has_many

Related object: L<Conch::Schema::Result::DeviceSpec>

=cut

__PACKAGE__->has_many(
  "device_specs",
  "Conch::Schema::Result::DeviceSpec",
  { "foreign.product_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_validate_criterias

Type: has_many

Related object: L<Conch::Schema::Result::DeviceValidateCriteria>

=cut

__PACKAGE__->has_many(
  "device_validate_criterias",
  "Conch::Schema::Result::DeviceValidateCriteria",
  { "foreign.product_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hardware_profile_settings

Type: has_many

Related object: L<Conch::Schema::Result::HardwareProfileSetting>

=cut

__PACKAGE__->has_many(
  "hardware_profile_settings",
  "Conch::Schema::Result::HardwareProfileSetting",
  { "foreign.profile_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 product

Type: belongs_to

Related object: L<Conch::Schema::Result::HardwareProduct>

=cut

__PACKAGE__->belongs_to(
  "product",
  "Conch::Schema::Result::HardwareProduct",
  { id => "product_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-07-19 13:32:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JJrJourFZqB3TjOAEeynaw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
