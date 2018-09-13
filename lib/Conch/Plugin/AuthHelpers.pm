=head1 NAME

Conch::Plugin::AuthHelpers

=head1 DESCRIPTION

Contains all convenience handlers for authentication

=head1 HELPERS

=cut

package Conch::Plugin::AuthHelpers;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub register ($self, $app, $conf) {

=head2 is_global_admin

	return $c->status(403) unless $c->is_global_admin

Verifies that the currently stashed user_id has admin rights on the
GLOBAL workspace

=cut

	$app->helper(
		is_global_admin => sub ($c) {
			return 0 unless $c->stash('user_id');

			return $c->db_workspaces->search({ 'workspace.name' => 'GLOBAL' })
				->search_related('user_workspace_roles',
					{ user_id => $c->stash('user_id'), role => 'admin' })
				->count;
		},
	);

=head2 is_workspace_admin

	return $c->status(403) unless $c->is_workspace_admin;

Verifies that the currently stashed user_id has 'admin' permission on the current workspace (as
specified by :workspace_id in the path).

=cut

	$app->helper(
		is_workspace_admin => sub ($c) {
			return $c->user_has_workspace_auth($c->stash('workspace_id'), 'admin');
		},
	);

=head2 user_has_workspace_auth

Verifies that the currently stashed user_id has (at least) this auth role on the specified
workspace (as indicated by :workspace_id in the path).

=cut

	$app->helper(
		user_has_workspace_auth => sub ($c, $workspace_id, $role_name) {
			return 0 unless $c->stash('user_id');

			return 1 if $c->is_global_admin;

			$c->db_workspaces->search({ 'workspace.id' => $workspace_id })
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
