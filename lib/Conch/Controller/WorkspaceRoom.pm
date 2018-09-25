=pod

=head1 NAME

Conch::Controller::WorkspaceRoom

=head1 METHODS

=cut

package Conch::Controller::WorkspaceRoom;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use List::Compare;

use Conch::Models;

with 'Conch::Role::MojoLog';

=head2 list

Get a list of rooms for the current workspace (as specified by :workspace_id in the path)

=cut

sub list ($c) {
	my $rooms = Conch::Model::WorkspaceRoom->new->list($c->stash('workspace_id'));
	$c->log->debug("Found ".scalar($rooms->@*)." workspace rooms");
	$c->status( 200, $rooms );
}


=head2 replace_rooms

Replace the room list for the current workspace (as specified by :workspace_id in the path),
given that
workspace is not GLOBAL, and provided that the user has the 'admin' role (GLOBAL
or local)

=cut

sub replace_rooms ($c) {
	return $c->status(403) unless $c->is_workspace_admin;

	my $body      = $c->req->json;

	unless ( $body && ref($body) eq 'ARRAY' ) {
		$c->log->warn("Input failed validation"); # FIXME use the validator

		return $c->status( 400 => {
			error => 'Array of datacenter room IDs required in request'
		});
	}

	my $uwr = $c->stash('user_workspace_role_rs')->single;

	if ( $uwr->workspace->name eq 'GLOBAL' ) {
		$c->log->warn("Attempt to modify GLOBAL workspace's rooms");
		return $c->status( 400 => {
			error => 'Cannot modify GLOBAL workspace' # [2018-07-30 sungo] why not?
		});
	}

	my $parent_rooms = Conch::Model::WorkspaceRoom->new
		->list_parent_workspace_rooms( $c->stash('workspace_id') );

	my @invalid_room_ids = List::Compare->new( $body, $parent_rooms )->get_unique;
	if (@invalid_room_ids) {
		my $s = join( ', ', @invalid_room_ids );
		$c->log->debug("These datacenter rooms are not a member of the paernt workspace: $s");

		return $c->status(409 => {
			error => "Datacenter room IDs must be members of the parent workspace: $s"
		});
	}

	my $room_attempt =
		Conch::Model::WorkspaceRoom->new->replace_workspace_rooms(
			$c->stash('workspace_id'),
			$body
		);
	$c->log->debug("Replaced the rooms in workspace ".$c->stash('workspace_id'));

	return $c->status( 200, $room_attempt );
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
