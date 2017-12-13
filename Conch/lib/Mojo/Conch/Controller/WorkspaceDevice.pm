package Mojo::Conch::Controller::WorkspaceDevice;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::Printer;

sub list ($c) {
  my $workspace_devices = $c->workspace_device->list(
    $c->stash('current_workspace')->id,
    # If 'active' query parameter specified, filter devices seen within in
    # 300 seconds (5 minutes)
    defined( $c->param('active') ) ? 300 : undef
  );


  my @devices = @$workspace_devices;
  @devices = grep { defined($_->graduated);  } @devices
    if ( defined( $c->param('graduated') ) and uc( $c->param('graduated') ) eq 'T' );

  @devices = grep { !defined($_->graduated) } @devices
    if ( defined( $c->param('graduated')) and uc( $c->param('graduated')) eq 'F' );

  @devices = grep { uc( $_->health ) eq uc( $c->param('health') ) } @devices
    if defined( $c->param('health') );

  # transform result from hashes to single string field, should be added last
  if (defined $c->param('ids_only')) {
    @devices = map { $_->id } @devices;
  } else {
    @devices = map { $_->as_v2_json } @devices;
  }

  $c->status(200, \@devices );
}

1;
