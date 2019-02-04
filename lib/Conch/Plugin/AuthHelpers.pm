package Conch::Plugin::AuthHelpers;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

=pod

=head1 NAME

Conch::Plugin::AuthHelpers

=head1 DESCRIPTION

Contains all convenience handlers for authentication

=head1 HELPERS

=cut

sub register ($self, $app, $config) {

=head2 is_system_admin

	return $c->status(403) unless $c->is_system_admin;

Verifies that the currently stashed user has the 'is_admin' flag set

=cut

	$app->helper(
		is_system_admin => sub ($c) {
			$c->stash('user') && $c->stash('user')->is_admin;
		},
	);

=head2 is_workspace_admin

	return $c->status(403) unless $c->is_workspace_admin;

Verifies that the currently stashed user_id has 'admin' permission on the current workspace (as
specified by :workspace_id in the path) or one of its ancestors.

=cut

	$app->helper(
		is_workspace_admin => sub ($c) {
			return $c->user_has_workspace_auth($c->stash('workspace_id'), 'admin');
		},
	);

=head2 user_has_workspace_auth

Verifies that the currently stashed user_id has (at least) this auth role on the specified
workspace (as indicated by :workspace_id in the path).

Users with the admin flag set will always return true, even if no user_workspace_role records
are present.

=cut

	$app->helper(
		user_has_workspace_auth => sub ($c, $workspace_id, $role_name) {
			return 0 if not $c->stash('user_id');
			return 0 if not $workspace_id;

			return 1 if $c->is_system_admin;

			$c->db_workspaces
				->and_workspaces_above($workspace_id)
				->related_resultset('user_workspace_roles')
				->user_has_permission($c->stash('user_id'), $role_name);
		},
	);

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
