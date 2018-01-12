package Conch::Controller::WorkspaceUser;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Printer;

sub list ($c) {
  my $users =
    $c->workspace_user->workspace_users( $c->stash('current_workspace')->id );
  $c->status( 200, [ map { $_->as_v1_json } @$users ]);
}

sub invite ($c) {
  my $body = $c->req->json;
  return $c->status( 400, { error => '"user" and "role " fields required ' } )
    unless ( $body->{user} and $body->{role} );

  my $ws         = $c->stash('current_workspace');
  my $maybe_role = $c->role->lookup_by_name( $body->{role} );

  if ( $maybe_role->is_fail ) {
    my $role_names = join( ', ', map { $_->name } @{ $c->role->list() } );
    return $c->status( 400,
      { error => '"role" must be one of: ' . $role_names } );
  }

  my $maybe_user = $c->user->lookup_by_email( $body->{user} );
  my $user;
  if ( $maybe_user->is_fail ) {
    my $password = $c->random_string( length => 10 );
    $user = $c->user->create( $body->{user}, $password );
    $c->mail->send_new_user_invite(
      { email => $user->email, password => $password } );
  }
  else {
    $user = $maybe_user->value;
    $c->mail->send_existing_user_invite(
      {
        email          => $user->email,
        workspace_name => $ws->name
      }
    );
  }

  $c->workspace->add_user_to_workspace( $user->id, $ws,
    $maybe_role->value->id );
  $c->status(201);
}

1;
