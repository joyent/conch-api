=pod

=head1 NAME

Conch::Controller::WorkspaceRoom

=head1 METHODS

=cut

package Conch::Controller::WorkspaceRoom;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use List::Compare;

use Conch::Models;

=head2 list

Get a list of rooms for the current stashed C<current_workspace>

=cut

sub list ($c) {
	my $rooms = Conch::Model::WorkspaceRoom->new->list(
		$c->stash('current_workspace')->id
	);
	$c->status( 200, $rooms );
}


=head2 replace_rooms

Replace the room list for the current stashed C<current_workspace>, given that
workspace is not GLOBAL, and provided that the user is an Administrator (GLOBAL
or local)

=cut

sub replace_rooms ($c) {
	my $workspace = $c->stash('current_workspace');
	my $body      = $c->req->json;
	unless ( $body && ref($body) eq 'ARRAY' ) {
		return $c->status( 400,
			{ error => 'Array of datacenter room IDs required in request' } );
	}
	if ( $workspace->name eq 'GLOBAL' ) {
		return $c->status( 400, { error => 'Cannot modify GLOBAL workspace' } );
	}

	unless ( $c->is_admin ) {
		return $c->status(
			403,
			{
				error => 'Only administrators may update the datacenter rooms'
			}
		);
	}

	my $parent_rooms = Conch::Model::WorkspaceRoom->new
		->list_parent_workspace_rooms( $workspace->id );

	my @invalid_room_ids = List::Compare->new( $body, $parent_rooms )->get_unique;
	if (@invalid_room_ids) {
		my $s = join( ', ', @invalid_room_ids );
		return $c->status(
			409,
			{
				error =>
					"Datacenter room IDs must be members of the parent workspace: $s"
			}
		);
	}

	my $room_attempt =
		Conch::Model::WorkspaceRoom->new->replace_workspace_rooms(
			$workspace->id, 
			$body
		);

	return $c->status( 200, $room_attempt );
}

1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

