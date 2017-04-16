use utf8;
package Conch::Schema::Result::HardwareProduct;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Schema::Result::HardwareProduct

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
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<hardware_product_alias_key>

=over 4

=item * L</alias>

=back

=cut

__PACKAGE__->add_unique_constraint("hardware_product_alias_key", ["alias"]);

=head2 C<hardware_product_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("hardware_product_name_key", ["name"]);

=head2 C<hardware_product_prefix_key>

=over 4

=item * L</prefix>

=back

=cut

__PACKAGE__->add_unique_constraint("hardware_product_prefix_key", ["prefix"]);

=head1 RELATIONS

=head2 devices

Type: has_many

Related object: L<Conch::Schema::Result::Device>

=cut

__PACKAGE__->has_many(
  "devices",
  "Conch::Schema::Result::Device",
  { "foreign.hardware_product" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hardware_product_profiles

Type: has_many

Related object: L<Conch::Schema::Result::HardwareProductProfile>

=cut

__PACKAGE__->has_many(
  "hardware_product_profiles",
  "Conch::Schema::Result::HardwareProductProfile",
  { "foreign.product_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hardware_totals

Type: has_many

Related object: L<Conch::Schema::Result::HardwareTotal>

=cut

__PACKAGE__->has_many(
  "hardware_totals",
  "Conch::Schema::Result::HardwareTotal",
  { "foreign.hardware_product" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vendor

Type: belongs_to

Related object: L<Conch::Schema::Result::HardwareVendor>

=cut

__PACKAGE__->belongs_to(
  "vendor",
  "Conch::Schema::Result::HardwareVendor",
  { id => "vendor" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2017-04-16 16:37:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:l8+2bReProGCL6viT2yOmQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
