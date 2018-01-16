package Conch::Controller::DeviceLocation;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Validate::UUID 'is_uuid';

use Data::Printer;

sub get ($c) {
  my $device_id      = $c->stash('current_device')->id;
  my $maybe_location = $c->device_location->lookup($device_id);
  return $c->status( 409,
    { error => "Device $device_id is not assigned to a rack" } )
    if $maybe_location->is_fail;

  $c->status( 200, $maybe_location->value->as_v1_json );
}

sub set ($c) {
  my $device_id = $c->stash('current_device')->id;
  my $body      = $c->req->json;
  return $c->status( 400,
    { error => 'rack_id and rack_unit must be defined the the request object' }
  ) unless $body->{rack_id} && $body->{rack_unit};

  my $assign =
    $c->device_location->assign( $device_id, $body->{rack_id},
    $body->{rack_unit} );
  return $c->status( 409, { error => $assign->failure } )
    if $assign->is_fail;

  $c->status(303);
  $c->redirect_to( $c->url_for("/device/$device_id/location")->to_abs );
}

sub delete ($c) {
  my $device_id = $c->stash('current_device')->id;
  my $unassign  = $c->device_location->unassign($device_id);
  return $c->status( 409,
    { error => "Device $device_id is not assigned to a rack" } )
    unless $unassign;

  $c->status(204);
}

1;
