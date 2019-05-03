use utf8;
package Conch::DB::Result::ValidationPlanMember;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::ValidationPlanMember

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<validation_plan_member>

=cut

__PACKAGE__->table("validation_plan_member");

=head1 ACCESSORS

=head2 validation_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 validation_plan_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "validation_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "validation_plan_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
);

=head1 PRIMARY KEY

=over 4

=item * L</validation_id>

=item * L</validation_plan_id>

=back

=cut

__PACKAGE__->set_primary_key("validation_id", "validation_plan_id");

=head1 RELATIONS

=head2 validation

Type: belongs_to

Related object: L<Conch::DB::Result::Validation>

=cut

__PACKAGE__->belongs_to(
  "validation",
  "Conch::DB::Result::Validation",
  { id => "validation_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 validation_plan

Type: belongs_to

Related object: L<Conch::DB::Result::ValidationPlan>

=cut

__PACKAGE__->belongs_to(
  "validation_plan",
  "Conch::DB::Result::ValidationPlan",
  { id => "validation_plan_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-09-17 14:52:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dZeoHWywkUv1QfTQ+HWxqA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
