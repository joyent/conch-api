=head1 NAME

Conch::Orc::Role::But

=head1 SYNOPSIS

	use Role::Tiny::With;
	with 'Conch::Orc::Role::But';

	<in calling code>

	my $obj = Class->new(foo => 'baz');
	$obj->update(foo => 'bar');


=head1 DESCRIPTION

A role to allow a user to bulk-update all attributes of a Moo object by abusing
C<<< ->new >>>. 

The notion here is to take an unknown hash, probably from a downstream client
via a JSON API or somesuch, and update an existing object without worrying
about that data containing shady keys.

The concept and base code comes from
L<https://shadow.cat/blog/matt-s-trout/do-you-copy/> and vaguely resembles a
Perl6 concept (L<https://docs.perl6.org/routine/but>)

=head1 METHODS

=cut

package Conch::Orc::Role::But;

use Role::Tiny;
use v5.20;


=head2 but

	my $new_self = $self->but(old => 'new');

Returns a copy of <$self> that contains the new values that were passed in.

=cut

sub but {
	my ($self, @args) = @_;
	ref($self)->new(%$self, @args);
}


=head2 update

	$self->update(old => 'new');

Updates C<$self> with the new values. Uses C<but> to get a new object but then
loads those attributes into the existing object.

=cut

sub update {
	my ($self, %updates) = @_;
	$self->%* = $self->but(%updates)->%*;
	return $self;
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

