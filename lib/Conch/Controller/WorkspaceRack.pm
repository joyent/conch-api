=pod

=head1 NAME

Conch::Controller::WorkspaceRack

=head1 METHODS

=cut

package Conch::Controller::WorkspaceRack;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::UUID 'is_uuid';

use Conch::Models;
with 'Conch::Role::MojoLog';

=head2 list

Get a list of racks for the current workspace (as specified by :workspace_id in the path).
Returns data matching the WorkspaceRackSummary json schema.

=cut

sub list ($c) {
	my $racks = Conch::Model::WorkspaceRack->new->list($c->stash('workspace_id'));
	$c->status( 200, $racks );
}

=head2 find_rack

Chainable action that takes the 'rack_id' provided in the path and looks it up in the
database, stashing it as 'current_ws_rack'.

=cut

sub find_rack ($c) {
	my $self = shift;

	my $rack_id = $c->stash('rack_id');

	if (not is_uuid($rack_id)) {
		$c->log->warn('Input failed validation');
		return $c->status(400 => { error => "Datacenter Rack ID must be a UUID. Got '$rack_id'." });
	}

	if (my $rack = Conch::Model::WorkspaceRack->lookup($c->stash('workspace_id'), $rack_id)) {
		$c->log->debug("Found rack $rack_id");
		$c->stash( current_ws_rack => $rack);
		return 1;
	}

	$c->log->debug("Could not find rack $rack_id");
	$c->status(404, { error => "Rack $rack_id not found" });
}

=head2 get_layout

Get the RackLayout for the current stashed C<current_ws_rack>

=cut

sub get_layout ($c) {
	my $layout = Conch::Model::WorkspaceRack->new->rack_layout(
		$c->stash('current_ws_rack')
	);
	$c->log->debug("Found rack layout ".$layout->{id});
	$c->status( 200, $layout );
}

=head2 add

Add a rack to a workspace, unless it is the GLOBAL workspace, provided the rack
is assigned to the parent workspace of this one, and provided the rack is not
already assigned via a datacenter room assignment

=cut

sub add ($c) {
	return $c->status(403) unless $c->is_admin;

	my $input = $c->validate_input('WorkspaceAddRack');
	if (not $input) {
		$c->log->warn("Input failed validation");
		return $c->status(400);
	}

	my $rack_id = delete $input->{id};

	my $uwr = $c->stash('user_workspace_role_rs')->single;

	return $c->status( 400, { error => "Cannot modify GLOBAL workspace" } )
		if $uwr->workspace->name eq 'GLOBAL';

	# FIXME: not checking that user has 'rw' permissions on this workspace

	unless ( Conch::Model::WorkspaceRack->rack_in_parent_workspace(
		$c->stash('workspace_id'),
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
		$c->stash('workspace_id'),
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

	Conch::Model::WorkspaceRack->new->add_to_workspace($c->stash('workspace_id'), $rack_id );

	# update rack with additional info, if provided.
	$c->db_datacenter_racks->search({ id => $rack_id })->update($input) if keys %$input;

	$c->status(303);
	$c->redirect_to( $c->url_for->to_abs . "/$rack_id" );
}


=head2 remove

Remove a rack from a workspace, unless it was implicitly assigned via a
datacenter room assignment

=cut

sub remove ($c) {
	return $c->status(403) unless $c->is_admin;

	my $uwr = $c->stash('user_workspace_role_rs')->single;

	return $c->status( 400, { error => "Cannot modify GLOBAL workspace" } )
		if $uwr->workspace->name eq 'GLOBAL';

	# FIXME: not checking that user has 'rw' permissions on this workspace

	my $remove_attempt = Conch::Model::WorkspaceRack->new->remove_from_workspace(
		$c->stash('workspace_id'),
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

	my $uwr = $c->stash('user_workspace_role_rs')->single;

	return $c->status(403) if $uwr->role eq 'ro';
	my $rack_id = $c->stash('current_ws_rack')->id;
	# FIXME: validate incoming data against json schema
	my $layout = $c->req->json;
	my @errors;
	my @updates;
	foreach my $device_id ( keys %{$layout} ) {
		my $rack_unit_start = $layout->{$device_id};
		my $loc = Conch::Model::DeviceLocation->new->assign(
			$device_id,
			$rack_id,
			$rack_unit_start,
		);
		if ($loc) {
			push @updates, $device_id;
		}
		else {
			push @errors,
				"Slot $rack_unit_start does not exist in the layout for rack $rack_id";
		}
	}

	return $c->status( 409, { updated => \@updates, errors => \@errors } )
		if scalar @errors;
	$c->status( 200, { updated => \@updates } );
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
