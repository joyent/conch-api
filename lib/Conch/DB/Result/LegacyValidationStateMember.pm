use utf8;
package Conch::DB::Result::LegacyValidationStateMember;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::LegacyValidationStateMember

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<legacy_validation_state_member>

=cut

__PACKAGE__->table("legacy_validation_state_member");

=head1 ACCESSORS

=head2 validation_state_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 legacy_validation_result_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 result_order

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "validation_state_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "legacy_validation_result_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "result_order",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</validation_state_id>

=item * L</legacy_validation_result_id>

=back

=cut

__PACKAGE__->set_primary_key("validation_state_id", "legacy_validation_result_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<l_validation_state_member_validation_state_id_result_order_key>

=over 4

=item * L</validation_state_id>

=item * L</result_order>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "l_validation_state_member_validation_state_id_result_order_key",
  ["validation_state_id", "result_order"],
);

=head1 RELATIONS

=head2 legacy_validation_result

Type: belongs_to

Related object: L<Conch::DB::Result::LegacyValidationResult>

=cut

__PACKAGE__->belongs_to(
  "legacy_validation_result",
  "Conch::DB::Result::LegacyValidationResult",
  { id => "legacy_validation_result_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 validation_state

Type: belongs_to

Related object: L<Conch::DB::Result::ValidationState>

=cut

__PACKAGE__->belongs_to(
  "validation_state",
  "Conch::DB::Result::ValidationState",
  { id => "validation_state_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pWVRpIBV17R4csWAOb5Y5w


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
