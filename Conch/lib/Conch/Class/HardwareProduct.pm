=pod

=head1 NAME

Conch::Class::HardwareProduct

=head1 METHODS

=cut

package Conch::Class::HardwareProduct;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::JsonV1';

=head2 id

=head2 name

=head2 alias

=head2 prefix

=head2 vendor

=head2 profile

=cut

has [
	qw(
		id
		name
		alias
		prefix
		vendor
		profile
		)
];


=head2 as_v1_json

=cut

sub as_v1_json {
	my $self = shift;
	{
		id      => $self->id,
		name    => $self->name,
		alias   => $self->alias,
		prefix  => $self->prefix,
		vendor  => $self->vendor,
		profile => $self->profile && $self->profile->as_v1_json
	};
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
