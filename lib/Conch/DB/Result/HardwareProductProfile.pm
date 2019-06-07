use utf8;
package Conch::DB::Result::HardwareProductProfile;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::HardwareProductProfile

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<hardware_product_profile>

=cut

__PACKAGE__->table("hardware_product_profile");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: gen_random_uuid()
  is_nullable: 0
  size: 16

=head2 hardware_product_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 rack_unit

  data_type: 'integer'
  is_nullable: 0

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

=head2 sata_hdd_num

  data_type: 'integer'
  is_nullable: 1

=head2 sata_hdd_size

  data_type: 'integer'
  is_nullable: 1

=head2 sata_hdd_slots

  data_type: 'text'
  is_nullable: 1

=head2 sas_hdd_num

  data_type: 'integer'
  is_nullable: 1

=head2 sas_hdd_size

  data_type: 'integer'
  is_nullable: 1

=head2 sas_hdd_slots

  data_type: 'text'
  is_nullable: 1

=head2 sata_ssd_num

  data_type: 'integer'
  is_nullable: 1

=head2 sata_ssd_size

  data_type: 'integer'
  is_nullable: 1

=head2 sata_ssd_slots

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

=head2 usb_num

  data_type: 'integer'
  is_nullable: 0

=head2 sas_ssd_num

  data_type: 'integer'
  is_nullable: 1

=head2 sas_ssd_size

  data_type: 'integer'
  is_nullable: 1

=head2 sas_ssd_slots

  data_type: 'text'
  is_nullable: 1

=head2 nvme_ssd_num

  data_type: 'integer'
  is_nullable: 1

=head2 nvme_ssd_size

  data_type: 'integer'
  is_nullable: 1

=head2 nvme_ssd_slots

  data_type: 'text'
  is_nullable: 1

=head2 raid_lun_num

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "uuid",
    default_value => \"gen_random_uuid()",
    is_nullable => 0,
    size => 16,
  },
  "hardware_product_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "rack_unit",
  { data_type => "integer", is_nullable => 0 },
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
  "sata_hdd_num",
  { data_type => "integer", is_nullable => 1 },
  "sata_hdd_size",
  { data_type => "integer", is_nullable => 1 },
  "sata_hdd_slots",
  { data_type => "text", is_nullable => 1 },
  "sas_hdd_num",
  { data_type => "integer", is_nullable => 1 },
  "sas_hdd_size",
  { data_type => "integer", is_nullable => 1 },
  "sas_hdd_slots",
  { data_type => "text", is_nullable => 1 },
  "sata_ssd_num",
  { data_type => "integer", is_nullable => 1 },
  "sata_ssd_size",
  { data_type => "integer", is_nullable => 1 },
  "sata_ssd_slots",
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
  "usb_num",
  { data_type => "integer", is_nullable => 0 },
  "sas_ssd_num",
  { data_type => "integer", is_nullable => 1 },
  "sas_ssd_size",
  { data_type => "integer", is_nullable => 1 },
  "sas_ssd_slots",
  { data_type => "text", is_nullable => 1 },
  "nvme_ssd_num",
  { data_type => "integer", is_nullable => 1 },
  "nvme_ssd_size",
  { data_type => "integer", is_nullable => 1 },
  "nvme_ssd_slots",
  { data_type => "text", is_nullable => 1 },
  "raid_lun_num",
  { data_type => "integer", is_nullable => 1 },
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

=item * L</hardware_product_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "hardware_product_profile_product_id_key",
  ["hardware_product_id"],
);

=head1 RELATIONS

=head2 hardware_product

Type: belongs_to

Related object: L<Conch::DB::Result::HardwareProduct>

=cut

__PACKAGE__->belongs_to(
  "hardware_product",
  "Conch::DB::Result::HardwareProduct",
  { id => "hardware_product_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A0d1Pmyg3nXXBUIx/wf1oA

__PACKAGE__->add_columns(
    '+hardware_product_id' => { is_serializable => 0 },
    '+created' => { is_serializable => 0 },
    '+updated' => { is_serializable => 0 },
    '+deactivated' => { is_serializable => 0 },
);

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
