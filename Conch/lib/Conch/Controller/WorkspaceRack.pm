package Conch::Controller::WorkspaceRack;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Validate::UUID 'is_uuid';
use Data::Printer;

sub list ($c) {
	my $racks = $c->workspace_rack->list( $c->stash('current_workspace')->id );
	$c->status( 200, $racks );
}

sub under ($c) {
	my $rack_id = $c->param('rack_id');
	unless ( is_uuid($rack_id) ) {
		$c->status( 400,
			{ error => "Datacenter Rack ID must be a UUID. Got '$rack_id'." } );
		return 0;
	}
	my $maybe_rack =
		$c->workspace_rack->lookup( $c->stash('current_workspace')->id, $rack_id );
	unless ($maybe_rack) {
		$c->status( 404, { error => "Rack $rack_id not found" } );
		return 0;
	}
	$c->stash( current_ws_rack => $maybe_rack );
	return 1;
}

# Return with layout
sub get_layout ($c) {
	return unless $c->under;
	my $layout = $c->workspace_rack->rack_layout( $c->stash('current_ws_rack') );
	$c->status( 200, $layout );
}

sub add ($c) {
	my $body = $c->req->json;
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
	unless ( $c->workspace_rack->rack_in_parent_workspace( $ws_id, $rack_id ) ) {
		return $c->status(
			409,
			{
				error => "Rack '$rack_id' must be assigned in parent workspace"
					. " to be assignable."
			},
		);
	}

	if ( $c->workspace_rack->rack_in_workspace_room( $ws_id, $rack_id ) ) {
		return $c->status(
			409,
			{
				error => "Rack '$rack_id' is already assigned to this "
					. "workspace via datacenter room assignment"
			},
		);
	}

	$c->workspace_rack->add_to_workspace( $ws_id, $rack_id );

	$c->status(303);
	$c->redirect_to( $c->url_for->to_abs . "/$rack_id" );
}

sub remove ($c) {
	return $c->status( 400, { error => "Cannot modify GLOBAL workspace" } )
		if $c->stash('current_workspace')->name eq 'GLOBAL';

	my $remove_attempt = $c->workspace_rack->remove_from_workspace(
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

# TODO: This is legacy code that is non-transactional. It should be reworked. --Lane
# Bulk update a rack layout.
sub assign_layout ($c) {
	my $rack_id = $c->stash('current_ws_rack')->id;

	my $layout = $c->req->json;
	my @errors;
	my @updates;
	foreach my $device_id ( keys %{$layout} ) {
		my $rack_unit = $layout->{$device_id};
		my $loc = $c->device_location->assign( $device_id, $rack_id, $rack_unit );
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
