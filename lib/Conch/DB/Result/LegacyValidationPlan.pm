use utf8;
package Conch::DB::Result::LegacyValidationPlan;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::LegacyValidationPlan

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<legacy_validation_plan>

=cut

__PACKAGE__->table("legacy_validation_plan");

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
  { "foreign.legacy_validation_plan_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 legacy_validation_plan_members

Type: has_many

Related object: L<Conch::DB::Result::LegacyValidationPlanMember>

=cut

__PACKAGE__->has_many(
  "legacy_validation_plan_members",
  "Conch::DB::Result::LegacyValidationPlanMember",
  { "foreign.legacy_validation_plan_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 legacy_validations

Type: many_to_many

Composing rels: L</legacy_validation_plan_members> -> legacy_validation

=cut

__PACKAGE__->many_to_many(
  "legacy_validations",
  "legacy_validation_plan_members",
  "legacy_validation",
);


# Created by DBIx::Class::Schema::Loader v0.07049
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IqhW95dBggKAwjne3trxXg

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
# vim: set sts=2 sw=2 et :
