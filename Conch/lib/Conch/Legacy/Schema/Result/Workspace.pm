use utf8;
package Conch::Legacy::Schema::Result::Workspace;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::Legacy::Schema::Result::Workspace

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

=head1 TABLE: C<workspace>

=cut

__PACKAGE__->table("workspace");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: uuid_generate_v4()
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
  is_foreign_key: 1
  is_nullable: 1
  size: 16

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
  "description",
  { data_type => "text", is_nullable => 1 },
  "parent_workspace_id",
  { data_type => "uuid", is_foreign_key => 1, is_nullable => 1, size => 16 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<workspace_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("workspace_name_key", ["name"]);

=head1 RELATIONS

=head2 parent_workspace

Type: belongs_to

Related object: L<Conch::Legacy::Schema::Result::Workspace>

=cut

__PACKAGE__->belongs_to(
  "parent_workspace",
  "Conch::Legacy::Schema::Result::Workspace",
  { id => "parent_workspace_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 user_workspace_roles

Type: has_many

Related object: L<Conch::Legacy::Schema::Result::UserWorkspaceRole>

=cut

__PACKAGE__->has_many(
  "user_workspace_roles",
  "Conch::Legacy::Schema::Result::UserWorkspaceRole",
  { "foreign.workspace_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workspace_datacenter_racks

Type: has_many

Related object: L<Conch::Legacy::Schema::Result::WorkspaceDatacenterRack>

=cut

__PACKAGE__->has_many(
  "workspace_datacenter_racks",
  "Conch::Legacy::Schema::Result::WorkspaceDatacenterRack",
  { "foreign.workspace_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workspace_datacenter_rooms

Type: has_many

Related object: L<Conch::Legacy::Schema::Result::WorkspaceDatacenterRoom>

=cut

__PACKAGE__->has_many(
  "workspace_datacenter_rooms",
  "Conch::Legacy::Schema::Result::WorkspaceDatacenterRoom",
  { "foreign.workspace_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workspaces

Type: has_many

Related object: L<Conch::Legacy::Schema::Result::Workspace>

=cut

__PACKAGE__->has_many(
  "workspaces",
  "Conch::Legacy::Schema::Result::Workspace",
  { "foreign.parent_workspace_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-29 19:26:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vy5s2eHsXSDWp4/1OtACwA

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

