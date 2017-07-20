use utf8;
package Conch::Schema::Result::TritonPostSetupStage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Schema::Result::TritonPostSetupStage

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

=head1 TABLE: C<triton_post_setup_stage>

=cut

__PACKAGE__->table("triton_post_setup_stage");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: gen_random_uuid()
  is_nullable: 0
  size: 16

=head2 product_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 1
  size: 16

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 requires

  data_type: 'text'
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 created

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
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 1, size => 16 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "requires",
  { data_type => "text", is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "created",
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

=head2 C<triton_post_setup_stage_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("triton_post_setup_stage_name_key", ["name"]);

=head1 RELATIONS

=head2 product

Type: belongs_to

Related object: L<Conch::Schema::Result::HardwareProduct>

=cut

__PACKAGE__->belongs_to(
  "product",
  "Conch::Schema::Result::HardwareProduct",
  { id => "product_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 triton_post_setups

Type: has_many

Related object: L<Conch::Schema::Result::TritonPostSetup>

=cut

__PACKAGE__->has_many(
  "triton_post_setups",
  "Conch::Schema::Result::TritonPostSetup",
  { "foreign.stage" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-07-19 21:27:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UAF5/6SVtl2VAWgSuxEHiQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
