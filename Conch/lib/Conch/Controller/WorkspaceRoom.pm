package Conch::Controller::WorkspaceRoom;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Printer;

sub list ($c) {
  my $rooms = $c->workspace_room->list( $c->stash('current_workspace')->id );
  $c->status( 200, [ map { $_->as_v1_json } @$rooms ] );
}

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
  unless ( $workspace->role eq 'Administrator' ) {
    return $c->status(
      401,
      {
        error => 'Only workspace administrators may update the datacenter rooms'
      }
    );
  }
  my $room_attempt =
    $c->workspace_room->replace_workspace_rooms( $workspace->id, $body );

  if ( $room_attempt->is_fail ) {
    return $c->status( 409, { error => $room_attempt->failure } );
  }
  return $c->status( 200, $room_attempt->value );
}

1;
