use utf8;
package Conch::Legacy::Schema::Result::HardwareProduct;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Legacy::Schema::Result::HardwareProduct

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

=item * L<DBIx::Class::TimeStamp>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

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

=head2 vendor

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
  is_nullable: 1

=head2 sku

  data_type: 'text'
  is_nullable: 1

=head2 generation_name

  data_type: 'text'
  is_nullable: 1

=head2 legacy_product_name

  data_type: 'text'
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
  "name",
  { data_type => "text", is_nullable => 0 },
  "alias",
  { data_type => "text", is_nullable => 0 },
  "prefix",
  { data_type => "text", is_nullable => 1 },
  "vendor",
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
  { data_type => "jsonb", is_nullable => 1 },
  "sku",
  { data_type => "text", is_nullable => 1 },
  "generation_name",
  { data_type => "text", is_nullable => 1 },
  "legacy_product_name",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<hardware_product_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("hardware_product_name_key", ["name"]);

=head2 C<hardware_product_sku_key>

=over 4

=item * L</sku>

=back

=cut

__PACKAGE__->add_unique_constraint("hardware_product_sku_key", ["sku"]);

=head1 RELATIONS

=head2 datacenter_rack_layouts

Type: has_many

Related object: L<Conch::Legacy::Schema::Result::DatacenterRackLayout>

=cut

__PACKAGE__->has_many(
  "datacenter_rack_layouts",
  "Conch::Legacy::Schema::Result::DatacenterRackLayout",
  { "foreign.product_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_roles

Type: has_many

Related object: L<Conch::Legacy::Schema::Result::DeviceRole>

=cut

__PACKAGE__->has_many(
  "device_roles",
  "Conch::Legacy::Schema::Result::DeviceRole",
  { "foreign.hardware_product_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 devices

Type: has_many

Related object: L<Conch::Legacy::Schema::Result::Device>

=cut

__PACKAGE__->has_many(
  "devices",
  "Conch::Legacy::Schema::Result::Device",
  { "foreign.hardware_product" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hardware_product_profile

Type: might_have

Related object: L<Conch::Legacy::Schema::Result::HardwareProductProfile>

=cut

__PACKAGE__->might_have(
  "hardware_product_profile",
  "Conch::Legacy::Schema::Result::HardwareProductProfile",
  { "foreign.product_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 validation_results

Type: has_many

Related object: L<Conch::Legacy::Schema::Result::ValidationResult>

=cut

__PACKAGE__->has_many(
  "validation_results",
  "Conch::Legacy::Schema::Result::ValidationResult",
  { "foreign.hardware_product_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vendor

Type: belongs_to

Related object: L<Conch::Legacy::Schema::Result::HardwareVendor>

=cut

__PACKAGE__->belongs_to(
  "vendor",
  "Conch::Legacy::Schema::Result::HardwareVendor",
  { id => "vendor" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-06-22 17:47:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UsXVcEzEU4u56W6BSxuKHg

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;


__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

