use utf8;
package Conch::Schema::Result::Triton;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Schema::Result::Triton

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

=head1 TABLE: C<triton>

=cut

__PACKAGE__->table("triton");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 triton_uuid

  data_type: 'uuid'
  is_nullable: 0
  size: 16

=head2 setup

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 post_setup

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 state

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
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "triton_uuid",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "setup",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "post_setup",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "state",
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

=head2 C<triton_triton_uuid_key>

=over 4

=item * L</triton_uuid>

=back

=cut

__PACKAGE__->add_unique_constraint("triton_triton_uuid_key", ["triton_uuid"]);

=head1 RELATIONS

=head2 id

Type: belongs_to

Related object: L<Conch::Schema::Result::Device>

=cut

__PACKAGE__->belongs_to(
  "id",
  "Conch::Schema::Result::Device",
  { id => "id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 triton_post_setups

Type: has_many

Related object: L<Conch::Schema::Result::TritonPostSetup>

=cut

__PACKAGE__->has_many(
  "triton_post_setups",
  "Conch::Schema::Result::TritonPostSetup",
  { "foreign.triton_uuid" => "self.triton_uuid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-10-05 17:32:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xf6UUzIvGD2xFc0xIWNOLw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
