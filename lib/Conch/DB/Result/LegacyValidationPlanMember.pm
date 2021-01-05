use utf8;
package Conch::DB::Result::LegacyValidationPlanMember;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::LegacyValidationPlanMember

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<legacy_validation_plan_member>

=cut

__PACKAGE__->table("legacy_validation_plan_member");

=head1 ACCESSORS

=head2 legacy_validation_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 legacy_validation_plan_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "legacy_validation_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "legacy_validation_plan_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
);

=head1 PRIMARY KEY

=over 4

=item * L</legacy_validation_id>

=item * L</legacy_validation_plan_id>

=back

=cut

__PACKAGE__->set_primary_key("legacy_validation_id", "legacy_validation_plan_id");

=head1 RELATIONS

=head2 legacy_validation

Type: belongs_to

Related object: L<Conch::DB::Result::LegacyValidation>

=cut

__PACKAGE__->belongs_to(
  "legacy_validation",
  "Conch::DB::Result::LegacyValidation",
  { id => "legacy_validation_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 legacy_validation_plan

Type: belongs_to

Related object: L<Conch::DB::Result::LegacyValidationPlan>

=cut

__PACKAGE__->belongs_to(
  "legacy_validation_plan",
  "Conch::DB::Result::LegacyValidationPlan",
  { id => "legacy_validation_plan_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4R0Ih5lVgK3H4wrjX7SFUw


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
