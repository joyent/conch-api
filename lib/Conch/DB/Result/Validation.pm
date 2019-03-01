use utf8;
package Conch::DB::Result::Validation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::Validation

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

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

Related object: L<Conch::DB::Result::ValidationPlanMember>

=cut

__PACKAGE__->has_many(
  "validation_plan_members",
  "Conch::DB::Result::ValidationPlanMember",
  { "foreign.validation_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 validation_results

Type: has_many

Related object: L<Conch::DB::Result::ValidationResult>

=cut

__PACKAGE__->has_many(
  "validation_results",
  "Conch::DB::Result::ValidationResult",
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


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-09-17 14:52:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Xi5ASzt2zuwUhj0wjj3a8A

__PACKAGE__->add_columns(
    '+module' => { is_serializable => 0 },
);

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
# vim: set ts=4 sts=4 sw=4 et :
