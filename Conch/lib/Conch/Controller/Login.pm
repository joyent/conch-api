package Conch::Controller::Login;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::IOLoop;
use Data::Printer;

sub authenticate ($c) {
  if ( my $basic_auth = $c->req->url->to_abs->userinfo ) {
    my ( $user, $password ) = split /:/, $basic_auth;
    my $a_user = $c->user->authenticate( $user, $password );

    $c->status( 401, { error => 'Invalid login' } )
      if $a_user->is_fail;
    $c->stash( user_id => $a_user->value->id )
      if $a_user->is_success;

    return $a_user->is_success;
  }

  my $user_id = $c->session('user');
  unless ($user_id) {
    $c->status(401);
    return 0;
  }
  my $user = $c->user->lookup($user_id);
  $c->stash( user_id => $user_id )
    if $user->is_success;
  return $user->is_success;
}

sub session_login ($c) {
  my $body = $c->req->json;

  return $c->status( 400, { error => '"user" and "password" required' } )
    unless $body->{user} and $body->{password};

  my $a_user = $c->user->authenticate( $body->{user}, $body->{password} );
  return $c->status( 401, { error => 'Invalid login' } )
    if $a_user->is_fail;

  $c->session( 'user' => $a_user->value->id );
  $c->status( 200, { status => 'successfully logged in' } );
}

sub session_logout ($c) {
  $c->session( expires => 1 );
  $c->status(204);
}

sub reset_password ($c) {
  my $body = $c->req->json;
  return $c->status( 400, { error => '"email" required' } )
    unless $body->{email};

  # check for the user and sent the email non-blocking to prevent timing attacks
  Mojo::IOLoop->subprocess(
    sub {
      my $a_user = $c->user->lookup_by_email( $body->{email} );
      if ($a_user) {
        my $random_pw = $c->random_string( length => 10 );
        $c->user->update_password( $a_user->value->id, $random_pw );
        $c->mail->send_password_reset_email(
          { email => $a_user->value->email, password => $random_pw } );
      }
    },
    sub { }
  );
  return $c->status(204);
}

1;
