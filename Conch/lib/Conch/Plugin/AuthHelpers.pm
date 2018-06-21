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

	if($c->global_auth("DC Operations")) {}

Verifies if the currently stashed user_id has this auth role on the GLOBAL
workspace

=cut

	$app->helper(
		global_auth => sub {
			my ( $c, $role_name ) = @_;
			return 0 unless $c->stash('user_id');

			my $ws = Conch::Model::Workspace->new->lookup_by_name('GLOBAL');
			return 0 unless $ws;

			my $user_ws = Conch::Model::Workspace->new->get_user_workspace(
				$c->stash('user_id'),
				$ws->id,
			);

			return 0 unless $user_ws;
			return 0 unless $user_ws->role eq $role_name;
			return 1;
		},
	);


=head2 is_global_admin

	return $c->status(403) unless $c->is_global_admin

Verifies that the currently stashed user_id has Administrator rights on the
GLOBAL workspace

=cut

	$app->helper(
		is_global_admin => sub {
			shift->global_auth('Administrator');
		}
	);

=head2 is_admin

	return $c->status(403) unless $c->is_admin;

Verifies that the currently stashed user_id is either a global admin or an
admin on the currently stashed 'current_workspace'

=cut

	$app->helper(
		is_admin => sub ($c) {
			return 1 if $c->is_global_admin;
			my $ws = $c->stash("current_workspace");
			return 0 unless $ws;
			return 1 if $ws->role eq "Administrator";
			return 0;
		}
	);

}

1;

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

