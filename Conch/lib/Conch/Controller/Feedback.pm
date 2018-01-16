package Conch::Controller::DeviceSettings;

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub send ($c) {
  my $user_id = $c->stash('user_id');
  my $body    = $c->req->json;
  my $message = $body->{message};
  my $subject = $body->{subject};

  #TODO: Send feedback email to the team --Lane

  $c->status(204);
}
