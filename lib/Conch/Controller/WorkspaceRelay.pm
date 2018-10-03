=pod

=head1 NAME

Conch::Controller::WorkspaceRelay

=head1 METHODS

=cut

package Conch::Controller::WorkspaceRelay;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;
with 'Conch::Role::MojoLog';

=head2 list

List all relays for the current workspace (as specified by :workspace_id in the path)

Response uses the WorkspaceRelays json schema.

=cut

sub list ($c) {
	my $relays = Conch::Model::WorkspaceRelay->new->list(
		$c->stash('workspace_id'),
		$c->param('active') ? 2 : undef,
		$c->param('no_devices') ? undef : 1,
	);

	$c->log->debug(
		"Found ".scalar($relays->@*).
		" relays in workspace ".$c->stash('workspace_id')
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
