=pod

=head1 NAME

Conch::Controller::Workspace

=head1 METHODS

=cut

package Conch::Controller::Workspace;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::UUID 'is_uuid';

use Conch::Models;

=head2 under

For all subroutes, this figures out the current Workspace, putting it in the
stash as C<current_workspace>

=cut

sub under ($c) {
	my $ws_id = $c->param('id');
	unless ( is_uuid($ws_id) ) {
		$c->status( 400,
			{ error => "Workspace ID must be a UUID. Got '$ws_id'." } );
		return 0;
	}
	my $ws = Conch::Model::Workspace->new->get_user_workspace(
		$c->stash('user_id'),
		$ws_id
	);
	if ($ws) {
		$c->stash( current_workspace => $ws );
		return 1;
	}
	else {
		$c->status( 404, { error => "Workspace $ws_id not found" } );
		return 0;
	}
}


=head2 list

Get a list of all workspaces available to current stashed C<user_id>

=cut

sub list ($c) {
	my $wss = Conch::Model::Workspace->new->get_user_workspaces(
		$c->stash('user_id')
	);
	$c->status( 200, $wss );
}


=head2 get

Get the details of the current workspace

=cut

sub get ($c) {
	if ( $c->under ) {
		$c->status( 200, $c->stash('current_workspace') );
	}
	else {
		return 0;
	}
}


=head2 get_sub_workspaces

Get all sub workspaces for the current stashed C<user_id> and current stashed
C<current_workspace>

=cut

sub get_sub_workspaces ($c) {
	my $sub_wss = Conch::Model::Workspace->new->get_user_sub_workspaces(
		$c->stash('user_id'),
		$c->stash('current_workspace')->id
	);
	$c->status( 200, $sub_wss );
}


=head2 create_sub_workspace

Create a new subworkspace for the current stashed C<current_workspace>

=cut

sub create_sub_workspace ($c) {
	my $body = $c->req->json;
	return $c->status(403) unless $c->is_admin;

	return $c->status( 400, { error => '"name" must be defined in request' } )
		unless $body->{name};

	my $ws = $c->stash('current_workspace');

	my $sub_ws_attempt = Conch::Model::Workspace->new->create_sub_workspace(
		$c->stash('user_id'),
		$ws->id,
		$ws->role_id,
		$body->{name},
		$body->{description}
	);

	return $c->status( 500, { error => 'unable to create a sub-workspace' } )
		unless $sub_ws_attempt;

	$c->status( 201, $sub_ws_attempt );
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

