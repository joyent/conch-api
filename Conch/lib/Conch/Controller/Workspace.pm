package Conch::Controller::Workspace;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Printer;

sub under ($c) {
  my $ws_id = $c->param('id');
  my $ws_attempt =
    $c->workspace->get_user_workspace( $c->stash('user_id'), $ws_id );
  if ( $ws_attempt->is_fail ) {
    $c->status( 404, { error => "Workspace $ws_id not found" } );
    return 0;
  }
  $c->stash( current_workspace => $ws_attempt->value );
  return 1;
}

sub list ($c) {
  my $wss = $c->workspace->get_user_workspaces( $c->stash('user_id') );
  $c->status( 200, [ map { $_->as_v1_json } @$wss ] );
}

sub get ($c) {
  if ( $c->under ) {
    $c->status( 200, $c->stash('current_workspace')->as_v1_json );
  }
  else {
    return 0;
  }
}

sub get_sub_workspaces ($c) {
  my $sub_wss = $c->workspace->get_user_sub_workspaces( $c->stash('user_id'),
    $c->stash('current_workspace')->id );
  $c->status( 200, [ map { $_->as_v1_json } @$sub_wss ] );
}

sub create_sub_workspace ($c) {
  my $body = $c->req->json;
  return $c->status( 401, { error => '"name" must be defined in request' } )
    unless $body->{name};
  my $ws             = $c->stash('current_workspace');
  my $sub_ws_attempt = $c->workspace->create_sub_workspace(
    $c->stash('user_id'), $ws->id, $ws->role_id,
    $body->{name},        $body->{description}
  );

  return $c->status( 500, { error => 'unable to create a sub-workspace' } )
    if $sub_ws_attempt->is_fail;

  $c->status( 201, $sub_ws_attempt->value->as_v1_json );
}

1;

