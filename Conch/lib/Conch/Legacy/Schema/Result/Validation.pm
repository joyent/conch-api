use utf8;
package Conch::Legacy::Schema::Result::Validation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Legacy::Schema::Result::Validation

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

=head1 TABLE: C<validation>

=cut

__PACKAGE__->table("validation");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: uuid_generate_v4()
  is_nullable: 0
  size: 16

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 version

  data_type: 'integer'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 0

=head2 module

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

=head2 deactivated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "uuid",
    default_value => \"uuid_generate_v4()",
    is_nullable => 0,
    size => 16,
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "version",
  { data_type => "integer", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 0 },
  "module",
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
  "deactivated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<validation_name_version_key>

=over 4

=item * L</name>

=item * L</version>

=back

=cut

__PACKAGE__->add_unique_constraint("validation_name_version_key", ["name", "version"]);

=head1 RELATIONS

=head2 validation_plan_members

Type: has_many

Related object: L<Conch::Legacy::Schema::Result::ValidationPlanMember>

=cut

__PACKAGE__->has_many(
  "validation_plan_members",
  "Conch::Legacy::Schema::Result::ValidationPlanMember",
  { "foreign.validation_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 validation_results

Type: has_many

Related object: L<Conch::Legacy::Schema::Result::ValidationResult>

=cut

__PACKAGE__->has_many(
  "validation_results",
  "Conch::Legacy::Schema::Result::ValidationResult",
  { "foreign.validation_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 validation_plans

Type: many_to_many

Composing rels: L</validation_plan_members> -> validation_plan

=cut

__PACKAGE__->many_to_many(
  "validation_plans",
  "validation_plan_members",
  "validation_plan",
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-06-22 17:47:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c5ZgQ3tlp3cv50iah2et9w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
