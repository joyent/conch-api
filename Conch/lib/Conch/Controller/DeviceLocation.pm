=pod

=head1 NAME

Conch::Controller::DeviceLocation

=head1 METHODS

=cut

package Conch::Controller::DeviceLocation;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::UUID 'is_uuid';

use Conch::Models;

=head2 get

Retrieves the location for the current device, via a serialized DeviceLocation
object

=cut

sub get ($c) {
	my $device_id      = $c->stash('current_device')->id;
	my $maybe_location = Conch::Model::DeviceLocation->new->lookup($device_id);
	return $c->status( 409,
		{ error => "Device $device_id is not assigned to a rack" } )
		unless $maybe_location;

	$c->status( 200, $maybe_location->TO_JSON );
}


=head2 set

Sets the location for a device, given a valid rack id and rack unit

=cut

sub set ($c) {
	my $device_id = $c->stash('current_device')->id;
	my $body      = $c->req->json;
	return $c->status( 400,
		{ error => 'rack_id and rack_unit must be defined the the request object' }
	) unless $body->{rack_id} && $body->{rack_unit};

	my $assign = Conch::Model::DeviceLocation->new->assign(
		$device_id,
		$body->{rack_id},
		$body->{rack_unit}
	);
	return $c->status(
		409,
		{
			    error => "Slot "
				. $body->{rack_unit}
				. " does not exist in the layout for rack "
				. $body->{rack_id}
		}
	) unless $assign;

	$c->status(303);
	$c->redirect_to( $c->url_for("/device/$device_id/location")->to_abs );
}



=head2 delete

Deletes the location data for a device, provided it has been assigned to a location

=cut

sub delete ($c) {
	my $device_id = $c->stash('current_device')->id;
	my $unassign  = Conch::Model::DeviceLocation->new->unassign($device_id);
	return $c->status( 409,
		{ error => "Device $device_id is not assigned to a rack" } )
		unless $unassign;

	$c->status(204);
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

