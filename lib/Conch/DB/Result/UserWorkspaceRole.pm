use utf8;
package Conch::DB::Result::UserWorkspaceRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::UserWorkspaceRole

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<Conch::DB::InflateColumn::Time>

=item * L<DBIx::Class::Helper::Row::ToJSON>

=back

=cut

__PACKAGE__->load_components("+Conch::DB::InflateColumn::Time", "Helper::Row::ToJSON");

=head1 TABLE: C<user_workspace_role>

=cut

__PACKAGE__->table("user_workspace_role");

=head1 ACCESSORS

=head2 user_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 workspace_id

  data_type: 'uuid'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 role

  data_type: 'enum'
  default_value: 'ro'
  extra: {custom_type_name => "user_workspace_role_enum",list => ["ro","rw","admin"]}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "workspace_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "role",
  {
    data_type => "enum",
    default_value => "ro",
    extra => {
      custom_type_name => "user_workspace_role_enum",
      list => ["ro", "rw", "admin"],
    },
    is_nullable => 0,
  },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<user_workspace_role_user_id_workspace_id_key>

=over 4

=item * L</user_id>

=item * L</workspace_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "user_workspace_role_user_id_workspace_id_key",
  ["user_id", "workspace_id"],
);

=head1 RELATIONS

=head2 user_account

Type: belongs_to

Related object: L<Conch::DB::Result::UserAccount>

=cut

__PACKAGE__->belongs_to(
  "user_account",
  "Conch::DB::Result::UserAccount",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 workspace

Type: belongs_to

Related object: L<Conch::DB::Result::Workspace>

=cut

__PACKAGE__->belongs_to(
  "workspace",
  "Conch::DB::Result::Workspace",
  { id => "workspace_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-08-09 14:14:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2k6gvOS1g//6V/o1gHknXw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
