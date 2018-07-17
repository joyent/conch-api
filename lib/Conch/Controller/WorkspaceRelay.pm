=pod

=head1 NAME

Conch::Controller::WorkspaceRelay

=head1 METHODS

=cut

package Conch::Controller::WorkspaceRelay;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;

=head2 list

List all relays for the current stashed C<current_workspace>

=cut

sub list ($c) {
	my $relays = Conch::Model::WorkspaceRelay->new->list(
		$c->stash('current_workspace')->id,
		$c->param('active') ? 2 : undef,
		$c->param('no_devices') ? undef : 1,
	);
	$c->status( 200, $relays );
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
