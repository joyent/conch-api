=pod

=head1 NAME

Conch::Model::Workspace

=head1 METHODS

=cut

package Conch::Model::Workspace;
use Mojo::Base -base, -signatures;

use Try::Tiny;
use Conch::Class::Workspace;
use Conch::Pg;

=head2 lookup_by_name

Look up a workspace by name.

=cut

sub lookup_by_name ( $self, $name ) {
	my $ret =
		Conch::Pg->new->db->select( 'workspace', undef, { name => $name } )->hash;

	return undef unless $ret;
	return Conch::Class::Workspace->new($ret);
}

=head2 add_user_to_workspace

Add a user to a workspace with a specified role.

=cut

sub add_user_to_workspace ( $self, $user_id, $ws_id, $role_id ) {

	# On conflict, set the role for the user
	Conch::Pg->new->db->query(
		q{
      INSERT INTO user_workspace_role (user_id, workspace_id, role_id)
      SELECT ?, ?, ?
      ON CONFLICT (user_id, workspace_id) DO UPDATE
        SET role_id = excluded.role_id
    }, $user_id, $ws_id, $role_id
	)->rows;
}

=head2 create_sub_workspace

Create a sub-workspace for a user. The user will have the same role as in the
parent workspace.

=cut

sub create_sub_workspace ( $self, $user_id, $parent_id, $role_id, $name,
	$description )
{
	my $db = Conch::Pg->new->db;

	my $tx = $db->begin;
	my ( $subws_id, $role_name );
	try {
		my $subws = $db->insert(
			'workspace',
			{
				name                => $name,
				description         => $description,
				parent_workspace_id => $parent_id
			},
			{ returning => 'id' }
		)->hash;

		die unless $subws;
		$subws_id = $subws->{id};

		$db->insert(
			'user_workspace_role',
			{
				user_id      => $user_id,
				workspace_id => $subws_id,
				role_id      => $role_id
			}
		);
		my $role = $db->select( 'role', 'name', { id => $role_id } )->hash;
		die undef unless $role;

		$role_name = $role->{name};
	}
	catch {
		$tx->rollback;
		return undef;
	};
	$tx->commit;

	return Conch::Class::Workspace->new(
		{
			id                  => $subws_id,
			name                => $name,
			description         => $description,
			role                => $role_name,
			role_id             => $role_id,
			parent_workspace_id => $parent_id
		}
	);
}

=head2 get_user_workspaces

Retrieve the list of workspaces associated with a user.

=cut

sub get_user_workspaces ( $self, $user_id ) {
	Conch::Pg->new->db->query(
		q{
    SELECT w.*, r.name as role, r.id as role_id
    FROM workspace w
    JOIN user_workspace_role uwr
    ON w.id = uwr.workspace_id
    JOIN user_account u
    on u.id = uwr.user_id
    JOIN role r
    on r.id = uwr.role_id
    WHERE u.id = ?::uuid
    }, $user_id
	)->hashes->map( sub { Conch::Class::Workspace->new($_) } )->to_array;
}

=head2 get_user_workspace

Look up a workspace by ID. Limited to workspaces associated with the specified
user ID.

=cut

sub get_user_workspace ( $self, $user_id, $ws_id ) {
	my $ret = Conch::Pg->new->db->query(
		q{
          SELECT w.*, r.name as role, r.id as role_id
          FROM workspace w
          JOIN user_workspace_role uwr
          ON w.id = uwr.workspace_id
          JOIN user_account u
          on u.id = uwr.user_id
          JOIN role r
          on r.id = uwr.role_id
          WHERE u.id = ?::uuid
            AND w.id = ?::uuid
          }, $user_id, $ws_id
	)->hash;
	return undef unless $ret;
	return Conch::Class::Workspace->new($ret);
}

=head2 get_user_sub_workspaces

Get all sub-workspace descendents of a workspace, recursively. Limited to workspaces
associated with the specified user ID.

=cut

sub get_user_sub_workspaces ( $self, $user_id, $ws_id ) {
	Conch::Pg->new->db->query(
		q{
    WITH RECURSIVE subworkspace (id, name, description, parent_workspace_id) AS (
        SELECT id, name, description, parent_workspace_id
        FROM workspace w
        WHERE parent_workspace_id = ?
      UNION
        SELECT w.id, w.name, w.description, w.parent_workspace_id
        FROM workspace w, subworkspace s
        WHERE w.parent_workspace_id = s.id
    )
    SELECT subworkspace.*,
      role.name as role, role.id as role_id
    FROM subworkspace
    JOIN user_workspace_role uwr
      ON subworkspace.id = uwr.workspace_id
    JOIN role
      ON role.id = uwr.role_id
    WHERE uwr.user_id = ?
  }, $ws_id, $user_id
	)->hashes->map( sub { Conch::Class::Workspace->new($_) } )->to_array;
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
