package Mojo::Conch::Controller::Relay;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Validate::UUID 'is_uuid';

use Data::Printer;


sub register ($c) {
  my $body    = $c->req->json;
  my $user_id = $c->stash('user_id');
  my $serial  = $body->{serial};

  return $c->status(400, { error => "'serial' attribute required in request" })
    unless defined($serial);

  my $relay_exists = $c->relay->lookup($serial);
  if ($relay_exists->is_fail) {
    my $version  = $body->{version};
    my $ipaddr   = $body->{ipaddr};
    my $ssh_port = $body->{ssh_port};
    my $alias    = $body->{alias};
    $c->relay->create( $serial, $version, $ipaddr, $ssh_port, $alias);
  }

  my $attempt = $c->relay->connect_user_relay($user_id, $relay_id);
  if ($attempt->is_fail) {
    $c->log->error($attempt->failure);
    return $c->status(500, { error => "unable to register relay '$serial'"  });
  }

  $c->status(204);
}

1;
