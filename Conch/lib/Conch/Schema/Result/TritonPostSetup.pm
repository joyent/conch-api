use utf8;
package Conch::Schema::Result::TritonPostSetup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Schema::Result::TritonPostSetup

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

=head1 TABLE: C<triton_post_setup>

=cut

__PACKAGE__->table("triton_post_setup");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: gen_random_uuid()
  is_nullable: 0
  size: 16

=head2 triton_uuid

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 stage

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 status

  data_type: 'text'
  is_nullable: 0

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
  "triton_uuid",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "stage",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "status",
  { data_type => "text", is_nullable => 0 },
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

=head2 C<triton_post_setup_triton_uuid_stage_key>

=over 4

=item * L</triton_uuid>

=item * L</stage>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "triton_post_setup_triton_uuid_stage_key",
  ["triton_uuid", "stage"],
);

=head1 RELATIONS

=head2 stage

Type: belongs_to

Related object: L<Conch::Schema::Result::TritonPostSetupStage>

=cut

__PACKAGE__->belongs_to(
  "stage",
  "Conch::Schema::Result::TritonPostSetupStage",
  { id => "stage" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 triton_post_setup_logs

Type: has_many

Related object: L<Conch::Schema::Result::TritonPostSetupLog>

=cut

__PACKAGE__->has_many(
  "triton_post_setup_logs",
  "Conch::Schema::Result::TritonPostSetupLog",
  { "foreign.stage_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 triton_uuid

Type: belongs_to

Related object: L<Conch::Schema::Result::Triton>

=cut

__PACKAGE__->belongs_to(
  "triton_uuid",
  "Conch::Schema::Result::Triton",
  { triton_uuid => "triton_uuid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2017-10-05 17:32:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uALZ+a6lBlRobafn5YWM0Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
