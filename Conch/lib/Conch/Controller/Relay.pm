package Conch::Controller::Relay;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Validate::UUID 'is_uuid';

use Data::Printer;

sub register ($c) {
  my $body    = $c->req->json;
  my $user_id = $c->stash('user_id');
  my $serial  = $body->{serial};

  return $c->status( 400,
    { error => "'serial' attribute required in request" } )
    unless defined($serial);

  my $relay_exists = $c->relay->lookup($serial);
  unless ( $relay_exists ) {
    $c->relay->create(
      $serial,
      $body->{version},
      $body->{ipaddr},
      $body->{ssh_port},
      $body->{alias},
    );
  }

  my $attempt = $c->relay->connect_user_relay( $user_id, $serial );

  unless ( $attempt ) {
    return $c->status( 500, { error => "unable to register relay '$serial'" } );
  }

  $c->status(204);
}

1;
