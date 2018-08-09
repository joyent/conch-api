use utf8;
package Conch::DB::Result::WorkspaceRecursive;

=head1 NAME

Conch::DB::Result::WorkspaceRecursive

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
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<workspace_recursive>

=cut

__PACKAGE__->table("workspace_recursive");
__PACKAGE__->result_source_instance->is_virtual(1);
__PACKAGE__->result_source_instance->view_definition(q{
WITH RECURSIVE workspace_recursive (id, name, description, parent_workspace_id) AS (
  SELECT workspace.id, workspace.name, workspace.description, workspace.parent_workspace_id
    FROM workspace
    WHERE workspace.parent_workspace_id = ?
  UNION
    SELECT child.id, child.name, child.description, child.parent_workspace_id
    FROM workspace child, workspace_recursive parent
    WHERE child.parent_workspace_id = parent.id
)
SELECT workspace_recursive.* FROM workspace_recursive
});

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  is_nullable: 0
  size: 16

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 parent_workspace_id

  data_type: 'uuid'
  is_nullable: 1
  size: 16

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "uuid", is_nullable => 0, size => 16 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "parent_workspace_id",
  { data_type => "uuid", is_nullable => 1, size => 16 },
);

=head2 user_workspace_roles

Type: has_many

Related object: L<Conch::DB::Result::UserWorkspaceRole>

=cut

__PACKAGE__->has_many(
  "user_workspace_roles",
  "Conch::DB::Result::UserWorkspaceRole",
  { "foreign.workspace_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
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
