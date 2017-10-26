package Conch::Control::Role;

use strict;
use warnings;
use Log::Any '$log';

use Data::Printer;
use Mojo::Pg;
use Mojo::Pg::Database;

use Exporter 'import';
our @EXPORT = qw( workspace_role_assignments is_valid_role_assignment );

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

sub workspace_role_assignments {
  my ($role) = @_;
  return $ROLE_ASSIGNMENT->{$role};
}

# Check whether a given role may assign the specified role
sub is_valid_role_assignment {
  my ( $role, $current_user_role ) = @_;
  return
    scalar( grep { $_ eq $role }
      @{ workspace_role_assignments($current_user_role) } );
}

1;
