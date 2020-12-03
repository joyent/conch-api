use utf8;
package Conch::DB::Result::HardwareProduct;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::HardwareProduct

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<hardware_product>

=cut

__PACKAGE__->table("hardware_product");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: gen_random_uuid()
  is_nullable: 0
  size: 16

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 alias

  data_type: 'text'
  is_nullable: 0

=head2 prefix

  data_type: 'text'
  is_nullable: 1

=head2 hardware_vendor_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

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

=head2 specification

  data_type: 'jsonb'
  default_value: '{}'
  is_nullable: 0

=head2 sku

  data_type: 'text'
  is_nullable: 0

=head2 generation_name

  data_type: 'text'
  is_nullable: 1

=head2 legacy_product_name

  data_type: 'text'
  is_nullable: 1

=head2 rack_unit_size

  data_type: 'integer'
  is_nullable: 0

=head2 validation_plan_id

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
  default_value: 0
  is_nullable: 0

=head2 cpu_type

  data_type: 'text'
  is_nullable: 0

=head2 dimms_num

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 ram_total

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 nics_num

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 sata_hdd_num

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 sata_hdd_size

  data_type: 'integer'
  is_nullable: 1

=head2 sata_hdd_slots

  data_type: 'text'
  is_nullable: 1

=head2 sas_hdd_num

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 sas_hdd_size

  data_type: 'integer'
  is_nullable: 1

=head2 sas_hdd_slots

  data_type: 'text'
  is_nullable: 1

=head2 sata_ssd_num

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 sata_ssd_size

  data_type: 'integer'
  is_nullable: 1

=head2 sata_ssd_slots

  data_type: 'text'
  is_nullable: 1

=head2 psu_total

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 usb_num

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 sas_ssd_num

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 sas_ssd_size

  data_type: 'integer'
  is_nullable: 1

=head2 sas_ssd_slots

  data_type: 'text'
  is_nullable: 1

=head2 nvme_ssd_num

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 nvme_ssd_size

  data_type: 'integer'
  is_nullable: 1

=head2 nvme_ssd_slots

  data_type: 'text'
  is_nullable: 1

=head2 raid_lun_num

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "uuid",
    default_value => \"gen_random_uuid()",
    is_nullable => 0,
    size => 16,
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "alias",
  { data_type => "text", is_nullable => 0 },
  "prefix",
  { data_type => "text", is_nullable => 1 },
  "hardware_vendor_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
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
  "specification",
  { data_type => "jsonb", default_value => "{}", is_nullable => 0 },
  "sku",
  { data_type => "text", is_nullable => 0 },
  "generation_name",
  { data_type => "text", is_nullable => 1 },
  "legacy_product_name",
  { data_type => "text", is_nullable => 1 },
  "rack_unit_size",
  { data_type => "integer", is_nullable => 0 },
  "validation_plan_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "purpose",
  { data_type => "text", is_nullable => 0 },
  "bios_firmware",
  { data_type => "text", is_nullable => 0 },
  "hba_firmware",
  { data_type => "text", is_nullable => 1 },
  "cpu_num",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "cpu_type",
  { data_type => "text", is_nullable => 0 },
  "dimms_num",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "ram_total",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "nics_num",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "sata_hdd_num",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "sata_hdd_size",
  { data_type => "integer", is_nullable => 1 },
  "sata_hdd_slots",
  { data_type => "text", is_nullable => 1 },
  "sas_hdd_num",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "sas_hdd_size",
  { data_type => "integer", is_nullable => 1 },
  "sas_hdd_slots",
  { data_type => "text", is_nullable => 1 },
  "sata_ssd_num",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "sata_ssd_size",
  { data_type => "integer", is_nullable => 1 },
  "sata_ssd_slots",
  { data_type => "text", is_nullable => 1 },
  "psu_total",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "usb_num",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "sas_ssd_num",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "sas_ssd_size",
  { data_type => "integer", is_nullable => 1 },
  "sas_ssd_slots",
  { data_type => "text", is_nullable => 1 },
  "nvme_ssd_num",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "nvme_ssd_size",
  { data_type => "integer", is_nullable => 1 },
  "nvme_ssd_slots",
  { data_type => "text", is_nullable => 1 },
  "raid_lun_num",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 devices

Type: has_many

Related object: L<Conch::DB::Result::Device>

=cut

__PACKAGE__->has_many(
  "devices",
  "Conch::DB::Result::Device",
  { "foreign.hardware_product_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hardware_vendor

Type: belongs_to

Related object: L<Conch::DB::Result::HardwareVendor>

=cut

__PACKAGE__->belongs_to(
  "hardware_vendor",
  "Conch::DB::Result::HardwareVendor",
  { id => "hardware_vendor_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 rack_layouts

Type: has_many

Related object: L<Conch::DB::Result::RackLayout>

=cut

__PACKAGE__->has_many(
  "rack_layouts",
  "Conch::DB::Result::RackLayout",
  { "foreign.hardware_product_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 validation_plan

Type: belongs_to

Related object: L<Conch::DB::Result::ValidationPlan>

=cut

__PACKAGE__->belongs_to(
  "validation_plan",
  "Conch::DB::Result::ValidationPlan",
  { id => "validation_plan_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 validation_states

Type: has_many

Related object: L<Conch::DB::Result::ValidationState>

=cut

__PACKAGE__->has_many(
  "validation_states",
  "Conch::DB::Result::ValidationState",
  { "foreign.hardware_product_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jh81nspu+x8IBhfHU063jQ

use experimental 'signatures';
use Mojo::JSON 'from_json';
use next::XS;

__PACKAGE__->add_columns(
    '+deactivated' => { is_serializable => 0 },
);

=head2 TO_JSON

Decode the json-encoded specification field for rendering in responses.

=cut

sub TO_JSON ($self) {
    my $data = $self->next::method(@_);

    $data->{specification} = from_json($data->{specification}) if defined $data->{specification};
    return $data;
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
