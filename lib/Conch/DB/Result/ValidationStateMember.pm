use utf8;
package Conch::DB::Result::ValidationStateMember;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::ValidationStateMember

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<validation_state_member>

=cut

__PACKAGE__->table("validation_state_member");

=head1 ACCESSORS

=head2 validation_state_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 validation_result_id

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
  "validation_result_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "result_order",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</validation_state_id>

=item * L</validation_result_id>

=back

=cut

__PACKAGE__->set_primary_key("validation_state_id", "validation_result_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<validation_state_member_validation_state_id_result_order_key>

=over 4

=item * L</validation_state_id>

=item * L</result_order>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "validation_state_member_validation_state_id_result_order_key",
  ["validation_state_id", "result_order"],
);

=head1 RELATIONS

=head2 validation_result

Type: belongs_to

Related object: L<Conch::DB::Result::ValidationResult>

=cut

__PACKAGE__->belongs_to(
  "validation_result",
  "Conch::DB::Result::ValidationResult",
  { id => "validation_result_id" },
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QmmAbZxCPyBfmUvcnNaMFA

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
