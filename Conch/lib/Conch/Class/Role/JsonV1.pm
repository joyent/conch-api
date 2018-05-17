=pod

=head1 NAME

Conch::Class::Role::JsonV1

=head1 DESCRIPTION

A role to provide a common JSON serializer for the v1 conch JSON format

=head1 METHODS

=cut

package Conch::Class::Role::JsonV1;
use Mojo::Base -role, -signatures;

use Data::Printer;



=head2 TO_JSON

Marshalls a hash-based object into a JSON object

=cut

sub TO_JSON {
	my $self   = shift;
	my %fields = %$self;
	return {%fields};
}

1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

