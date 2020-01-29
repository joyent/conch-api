use utf8;
package Conch::DB::Result::ValidationPlan;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::ValidationPlan

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<validation_plan>

=cut

__PACKAGE__->table("validation_plan");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: gen_random_uuid()
  is_nullable: 0
  size: 16

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 0

=head2 created

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
    default_value => \"gen_random_uuid()",
    is_nullable => 0,
    size => 16,
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 0 },
  "created",
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

=head1 RELATIONS

=head2 hardware_products

Type: has_many

Related object: L<Conch::DB::Result::HardwareProduct>

=cut

__PACKAGE__->has_many(
  "hardware_products",
  "Conch::DB::Result::HardwareProduct",
  { "foreign.validation_plan_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 validation_plan_members

Type: has_many

Related object: L<Conch::DB::Result::ValidationPlanMember>

=cut

__PACKAGE__->has_many(
  "validation_plan_members",
  "Conch::DB::Result::ValidationPlanMember",
  { "foreign.validation_plan_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 validation_states

Type: has_many

Related object: L<Conch::DB::Result::ValidationState>

=cut

__PACKAGE__->has_many(
  "validation_states",
  "Conch::DB::Result::ValidationState",
  { "foreign.validation_plan_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 validations

Type: many_to_many

Composing rels: L</validation_plan_members> -> validation

=cut

__PACKAGE__->many_to_many("validations", "validation_plan_members", "validation");


# Created by DBIx::Class::Schema::Loader v0.07049
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8Va+mP/1Ujni4L+AHcEtfA

__PACKAGE__->add_columns(
    '+deactivated' => { is_serializable => 0 },
);

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
