package Conch::Controller::WorkspaceRelay;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Printer;

sub list ($c) {
  my $relays = $c->workspace_relay->list( $c->stash('current_workspace')->id,
    $c->param('active') ? 2 : undef );
  $c->status( 200, [ map { $_->as_v1_json } @$relays ] );
}

1;
