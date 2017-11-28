package Conch::Control::Role;

use strict;
use warnings;
use Log::Any '$log';

use Data::Printer;
use Mojo::Pg;
use Mojo::Pg::Database;

use Exporter 'import';
our @EXPORT = qw( assignable_roles );

# Map the roles a given role can assign to other users. Administrator can
# bestow any privileges. Integrator Managers can invite Integrators and
# Read-only users. DC Operations can invite other DC Operations and read-only
my $ROLE_ASSIGNMENT = {
  Administrator => [
    'Administrator',
    'Read-only',
    'DC Operations',
    'Integrator',
    'Integrator Manager',

  ],
  'Integrator Manager' => [ 'Integrator',    'Read-only' ],
  'DC Operations'      => [ 'DC Operations', 'Read-only' ]
};

# Give the roles a given role may assign
sub assignable_roles {
  my ( $role ) = @_;
  return $ROLE_ASSIGNMENT->{$role};
}

1;
