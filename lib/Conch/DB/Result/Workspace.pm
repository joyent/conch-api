use utf8;
package Conch::DB::Result::Workspace;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::Workspace

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

=head1 TABLE: C<workspace>

=cut

__PACKAGE__->table("workspace");

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
    default_value => \"gen_random_uuid()",
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

=head2 organization_workspace_roles

Type: has_many

Related object: L<Conch::DB::Result::OrganizationWorkspaceRole>

=cut

__PACKAGE__->has_many(
  "organization_workspace_roles",
  "Conch::DB::Result::OrganizationWorkspaceRole",
  { "foreign.workspace_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 parent_workspace

Type: belongs_to

Related object: L<Conch::DB::Result::Workspace>

=cut

__PACKAGE__->belongs_to(
  "parent_workspace",
  "Conch::DB::Result::Workspace",
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

Related object: L<Conch::DB::Result::UserWorkspaceRole>

=cut

__PACKAGE__->has_many(
  "user_workspace_roles",
  "Conch::DB::Result::UserWorkspaceRole",
  { "foreign.workspace_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workspace_racks

Type: has_many

Related object: L<Conch::DB::Result::WorkspaceRack>

=cut

__PACKAGE__->has_many(
  "workspace_racks",
  "Conch::DB::Result::WorkspaceRack",
  { "foreign.workspace_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 workspaces

Type: has_many

Related object: L<Conch::DB::Result::Workspace>

=cut

__PACKAGE__->has_many(
  "workspaces",
  "Conch::DB::Result::Workspace",
  { "foreign.parent_workspace_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organizations

Type: many_to_many

Composing rels: L</organization_workspace_roles> -> organization

=cut

__PACKAGE__->many_to_many(
  "organizations",
  "organization_workspace_roles",
  "organization",
);

=head2 racks

Type: many_to_many

Composing rels: L</workspace_racks> -> rack

=cut

__PACKAGE__->many_to_many("racks", "workspace_racks", "rack");

=head2 user_accounts

Type: many_to_many

Composing rels: L</user_workspace_roles> -> user_account

=cut

__PACKAGE__->many_to_many("user_accounts", "user_workspace_roles", "user_account");


# Created by DBIx::Class::Schema::Loader v0.07049
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Urk+hHQeLcSJ6VUznFO6Hg

use experimental 'signatures';
use Sub::Install;

=head2 TO_JSON

Include information about the user's role, if available.

=cut

sub TO_JSON ($self) {
    my $data = $self->next::method(@_);

    # check for column that would have been added via
    # Conch::DB::ResultSet::Workspace::add_role_column or
    # Conch::DB::ResultSet::Workspace::with_role_via_data_for_user
    if (my $role = $self->role) {
        $data->{role} = $role;
    }
    elsif (my $user_id = $self->user_id_for_role) {
        my $role_via = $self->result_source->resultset->role_via_for_user($self->id, $user_id);
        Carp::croak('tried to get role data for a user that has no role for this workspace: workspace_id ', $self->id, ', user_id ', $user_id) if not $role_via;

        $data->{role} = $role_via->role;
        $data->{role_via} = $role_via->workspace_id if $role_via->workspace_id ne $self->id;
    }

    return $data;
}

=head2 role

Accessor for informational column, which is by the serializer in the result data.

=head2 user_id_for_role

Accessor for informational column, which is used by the serializer to signal we should fetch
and include inherited role data for the user.

=head2 organization_id_for_role

Accessor for informational column, which is used by the serializer to signal we should fetch
and include inherited role data for the organization.

=cut

foreach my $column (qw(role user_id_for_role organization_id_for_role)) {
    Sub::Install::install_sub({
        as   => $column,
        code => sub {
            my $self = shift;
            if (@_) {
                # DBIC has no public way of setting this outside of the constructor :/
                $self->{_column_data}{$column} = shift;
            }
            else {
                $self->has_column_loaded($column) && $self->get_column($column);
            }
        },
    });
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
