=pod

=head1 NAME

Conch::Controller::WorkspaceRack

=head1 METHODS

=cut

package Conch::Controller::WorkspaceRack;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::UUID 'is_uuid';

use Conch::Models;

=head2 list

Get a list of racks for the current stashed C<current_workspace>

=cut

sub list ($c) {
	my $racks = Conch::Model::WorkspaceRack->new->list(
		$c->stash('current_workspace')->id
	);
	$c->status( 200, $racks );
}


=head2 under

For all subroutes, grab the rack ID and stash the relevant rack in
C<current_ws_rack>

=cut

sub under ($c) {
	my $rack_id = $c->param('rack_id');
	unless ( is_uuid($rack_id) ) {
		$c->status( 400,
			{ error => "Datacenter Rack ID must be a UUID. Got '$rack_id'." } );
		return 0;
	}
	my $maybe_rack = Conch::Model::WorkspaceRack->lookup(
		$c->stash('current_workspace')->id,
		$rack_id
	);
	unless ($maybe_rack) {
		$c->status( 404, { error => "Rack $rack_id not found" } );
		return 0;
	}
	$c->stash( current_ws_rack => $maybe_rack );
	return 1;
}


=head2 get_layout

Get the RackLayout for the current stashed C<current_ws_rack>

=cut

sub get_layout ($c) {
	return unless $c->under;
	my $layout = Conch::Model::WorkspaceRack->new->rack_layout(
		$c->stash('current_ws_rack')
	);
	$c->status( 200, $layout );
}

=head2 add

Add a rack to a workspace, unless it is the GLOBAL workspace, provided the rack
is assigned to the parent workspace of this one, and provided the rack is not
already assigned via a datacenter room assignment

=cut

sub add ($c) {
	my $body = $c->req->json;
	return $c->status(403) unless $c->is_admin;

	return $c->status( 400,
		{ error => 'JSON object with "id" Rack ID field required' } )
		unless ( $body && $body->{id} );
	my $rack_id = $body->{id};

	return $c->status( 400,
		{ error => "Rack ID must be a UUID. Got '$rack_id'." } )
		unless is_uuid($rack_id);

	return $c->status( 400, { error => "Cannot modify GLOBAL workspace" } )
		if $c->stash('current_workspace')->name eq 'GLOBAL';

	my $ws_id = $c->stash('current_workspace')->id;
	unless ( Conch::Model::WorkspaceRack->rack_in_parent_workspace(
		$ws_id,
		$rack_id
	)) {
		return $c->status(
			409,
			{
				error => "Rack '$rack_id' must be assigned in parent workspace"
					. " to be assignable."
			},
		);
	}

	if ( Conch::Model::WorkspaceRack->new->rack_in_workspace_room(
		$ws_id,
		$rack_id
	) ) {
		return $c->status(
			409,
			{
				error => "Rack '$rack_id' is already assigned to this "
					. "workspace via datacenter room assignment"
			},
		);
	}

	Conch::Model::WorkspaceRack->new->add_to_workspace( $ws_id, $rack_id );

	$c->status(303);
	$c->redirect_to( $c->url_for->to_abs . "/$rack_id" );
}


=head2 remove

Remove a rack from a workspace, unless it was implicitly assigned via a
datacenter room assignment

=cut

sub remove ($c) {
	return $c->status(403) unless $c->is_admin;

	return $c->status( 400, { error => "Cannot modify GLOBAL workspace" } )
		if $c->stash('current_workspace')->name eq 'GLOBAL';

	my $remove_attempt = Conch::Model::WorkspaceRack->new->remove_from_workspace(
		$c->stash('current_workspace')->id,
		$c->stash('current_ws_rack')->id,
	);
	return $c->status(204) if $remove_attempt;

	return $c->status(
		409,
		{
			    error => "Rack '"
				. $c->stash('current_ws_rack')->id
				. "' is not explicitly assigned to the "
				. "workspace. It is assigned implicitly via a datacenter room "
				. "assignment."
		}
	);
}


=head2 assign_layout

Assign the full layout for a rack

=cut

# TODO: This is legacy code that is non-transactional. It should be reworked. --Lane
# Bulk update a rack layout.
sub assign_layout ($c) {
	return $c->status(403) if $c->stash('current_workspace')->role eq 'Read-only';
	my $rack_id = $c->stash('current_ws_rack')->id;

	my $layout = $c->req->json;
	my @errors;
	my @updates;
	foreach my $device_id ( keys %{$layout} ) {
		my $rack_unit = $layout->{$device_id};
		my $loc = Conch::Model::DeviceLocation->new->assign(
			$device_id,
			$rack_id,
			$rack_unit
		);
		if ($loc) {
			push @updates, $device_id;
		}
		else {
			push @errors,
				"Slot $rack_unit does not exist in the layout for rack $rack_id";
		}
	}

	return $c->status( 409, { updated => \@updates, errors => \@errors } )
		if scalar @errors;
	$c->status( 200, { updated => \@updates } );
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

