package Conch::Controller::WorkspaceProblem;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Legacy::Schema;
use Conch::Legacy::Control::Problem 'get_problems';

# get_problems needs to be heavily re-worked. For now, use the legacy code using DBIC
sub list ($c) {
  my $schema = Conch::Legacy::Schema->connect( $c->pg->dsn, $c->pg->username,
    $c->pg->password );

  my $problems = get_problems(
    $schema,
    $c->stash('user_id'),
    $c->stash('current_workspace')->id
  );
  $c->status( 200, $problems );
}

1;
