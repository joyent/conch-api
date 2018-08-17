use utf8;
package Conch::DB::Result::HardwareProduct;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::HardwareProduct

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<Conch::DB::InflateColumn::Time>

=item * L<Conch::DB::ToJSON>

=back

=cut

__PACKAGE__->load_components("+Conch::DB::InflateColumn::Time", "+Conch::DB::ToJSON");

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

Related object: L<Conch::DB::Result::DatacenterRackLayout>

=cut

__PACKAGE__->has_many(
  "datacenter_rack_layouts",
  "Conch::DB::Result::DatacenterRackLayout",
  { "foreign.product_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 device_roles

Type: has_many

Related object: L<Conch::DB::Result::DeviceRole>

=cut

__PACKAGE__->has_many(
  "device_roles",
  "Conch::DB::Result::DeviceRole",
  { "foreign.hardware_product_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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

=head2 hardware_product_profile

Type: might_have

Related object: L<Conch::DB::Result::HardwareProductProfile>

=cut

__PACKAGE__->might_have(
  "hardware_product_profile",
  "Conch::DB::Result::HardwareProductProfile",
  { "foreign.product_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 validation_results

Type: has_many

Related object: L<Conch::DB::Result::ValidationResult>

=cut

__PACKAGE__->has_many(
  "validation_results",
  "Conch::DB::Result::ValidationResult",
  { "foreign.hardware_product_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vendor

Type: belongs_to

Related object: L<Conch::DB::Result::HardwareVendor>

=cut

__PACKAGE__->belongs_to(
  "vendor",
  "Conch::DB::Result::HardwareVendor",
  { id => "vendor" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-08-15 16:08:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sCsFRfbsWv0tJzzdFZggCw


# You can replace this text with custom code or comments, and it will be preserved on regeneration


my %s;
foreach (qw[
	id
	name
	alias
	prefix
	vendor
	created
	updated
	specification
	sku
	generation_name
	legacy_product_name
]) {
	$s{"+$_"} = { is_serializable => 1 }
}

$s{"+deactivated"} = { is_serializable => 0 };

__PACKAGE__->add_columns(%s);

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
