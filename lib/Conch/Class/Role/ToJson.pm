=pod

=head1 NAME

Conch::Class::Role::ToJson

=head1 DESCRIPTION

A role to provide a common JSON serializer that serializes the fields of the
object.

=head1 METHODS

=cut

package Conch::Class::Role::ToJson;
use Mojo::Base -role, -signatures;

use Data::Printer;



=head2 TO_JSON

Marshalls a hash-based object into a JSON object hash using the fields of the
object.

=cut

sub TO_JSON {
	my $self   = shift;
	my %fields = %$self;
	return {%fields};
}

1;

__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

