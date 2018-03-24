=head1 NAME

Conch::Minion - Conch Minion instance

=head1 DESCRIPTION

A singleton class to hide away a common L<Minion> instance

=head1 SYNOPSIS

As soon as possible, initialize a single instance.

	Conch::Pg->new($pg_uri);

After that, all other access can be through C<Conch::Pg->new()>.

=head1 METHODS

=cut

package Conch::Minion;
use strict;
use warnings;
use v5.10;

use base qw(Class::StrongSingleton);
use Conch::Pg;
use Minion;

=head2 new

Create or reference the Minion singleton object. Must be called after a
C<Conch::Pg> instance is initialized.

=cut

sub new {
	my ( $class, $pg_uri ) = @_;
	my $self = {};

	$self->{minion} = Minion->new( Pg => Conch::Pg->new->pg );
	bless( $self, $class );

	$self->_init_StrongSingleton();
	return $self;
}

=head2 minion

Direct access to the L<Minion> object

=cut

sub minion { shift->{minion}; }

=head1 PROXYED METHODS

These methods are all proxy calls into the Minion object. They are available to
allow Conch::Minion to be a drop-in replacement for our usage of Minion so far.

=head2 enqueue

=head2 dequeue

=cut

sub enqueue { shift->minion->enqueue(@_); }
sub dequeue { shift->minion->dequeue(@_); }
sub stats   { shift->minion->stats(@_); }

1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
