=head1 NAME

Conch::Plugin::AuthHelpers

=head1 DESCRIPTION

Contains all convenience handlers for authentication

=head1 HELPERS

=cut

package Conch::Plugin::AuthHelpers;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub register ($self, $app, $conf) {

=head2 global_auth

	if ($c->global_auth('rw')) { ... }

Verifies if the currently stashed user_id has this auth role on the GLOBAL
workspace

=cut

	$app->helper(
		global_auth => sub {
			my ( $c, $role_name ) = @_;
			return 0 unless $c->stash('user_id');

			# FIXME: currently does an exact match. should we return true
			# if we ask about 'rw' and the user has 'admin?

			return $c->db_workspaces->search({ 'me.name' => 'GLOBAL' })
				->search_related('user_workspace_roles',
					{ user_id => $c->stash('user_id'), role => $role_name })
				->count;
		},
	);


=head2 is_global_admin

	return $c->status(403) unless $c->is_global_admin

Verifies that the currently stashed user_id has admin rights on the
GLOBAL workspace

=cut

	$app->helper(
		is_global_admin => sub {
			shift->global_auth('admin');
		}
	);

=head2 is_admin

	return $c->status(403) unless $c->is_admin;

Verifies that the currently stashed user_id is either a global admin or an
admin on the current workspace (as specified by :workspace_id in the path)

=cut

	$app->helper(
		is_admin => sub ($c) {
			return 1 if $c->is_global_admin;

			my $uwr = $c->stash('user')->search_related('user_workspace_roles',
				{ workspace_id => $c->stash('workspace_id') },
			)->single;
			return 0 unless $uwr;
			return 1 if $uwr->role eq 'admin';
			return 0;
		}
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
