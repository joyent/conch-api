use utf8;
package Conch::DB::Schema::Result::Workspace;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Schema::Result::Workspace

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::Helper::Row::ToJSON>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "Helper::Row::ToJSON");

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

Related object: L<Conch::DB::Schema::Result::Workspace>

=cut

__PACKAGE__->belongs_to(
  "parent_workspace",
  "Conch::DB::Schema::Result::Workspace",
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

Related object: L<Conch::DB::Schema::Result::UserWorkspaceRole>

=cut

__PACKAGE__->has_many(
  "user_workspace_roles",
  "Conch::DB::Schema::Result::UserWorkspaceRole",
  { "foreign.workspace_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workspace_datacenter_racks

Type: has_many

Related object: L<Conch::DB::Schema::Result::WorkspaceDatacenterRack>

=cut

__PACKAGE__->has_many(
  "workspace_datacenter_racks",
  "Conch::DB::Schema::Result::WorkspaceDatacenterRack",
  { "foreign.workspace_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workspace_datacenter_rooms

Type: has_many

Related object: L<Conch::DB::Schema::Result::WorkspaceDatacenterRoom>

=cut

__PACKAGE__->has_many(
  "workspace_datacenter_rooms",
  "Conch::DB::Schema::Result::WorkspaceDatacenterRoom",
  { "foreign.workspace_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workspaces

Type: has_many

Related object: L<Conch::DB::Schema::Result::Workspace>

=cut

__PACKAGE__->has_many(
  "workspaces",
  "Conch::DB::Schema::Result::Workspace",
  { "foreign.parent_workspace_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-07-16 11:13:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0QmkYyw9wml+K6VGt/LtGw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

