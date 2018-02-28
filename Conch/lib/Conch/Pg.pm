=head1 NAME

Conch::Pg

=head1 DESCRIPTION

A singleton class to hide away a common Mojo::Pg instance

=head1 SYNOPSIS

As soon as possible, initialize a single instance.

	Conch::Pg->new($pg_uri);

After that, all other access can be through C<Conch::Pg->new()>.

=head1 METHODS

=cut

package Conch::Pg;
use strict;
use warnings;
use v5.10;

use base qw(Class::StrongSingleton);
use Mojo::Pg;

=head2 new

Create a new object. Pass in a postgres URI the first time the class is used.
Afterwards, parameters are not necessary and will be ignored.

=cut

sub new {
	my ($class, $pg_uri) = @_;
	my $self = {};

	$self->{pg} = Mojo::Pg->new($pg_uri);
	bless($self, $class);

	$self->_init_StrongSingleton();
	return $self;
}

=head2 pg

Direct access to the Mojo::Pg object

=cut

sub pg { shift->{pg}; }

=head1 PROXYED METHODS

These methods are all proxy calls into the Mojo::Pg object. They are available
to allow Conch::Pg to be a drop-in replacement for our usage, thus far, of
Mojo::Pg

=head2 db

=head2 dsn

=head2 username

=head2 password

=cut


sub db { shift->{pg}->db; }
sub dsn { shift->{pg}->dsn; }
sub username { shift->{pg}->username; }
sub password { shift->{pg}->password; }
 

1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

