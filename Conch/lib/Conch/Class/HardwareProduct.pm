=pod

=head1 NAME

Conch::Class::HardwareProduct

=head1 METHODS

=cut

package Conch::Class::HardwareProduct;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::ToJson';

=head2 id

=head2 name

=head2 alias

=head2 prefix

=head2 vendor

=head2 profile

=head2 specification

=head2 sku

=head2 generation_name

=head2 legacy_product_name

=cut

has [
	qw(
		id
		alias
		generation_name
		legacy_product_name
		name
		prefix
		profile
		sku
		specification
		vendor
	)
];


=head2 TO_JSON

=cut

sub TO_JSON {
	my $self = shift;
	{
		id                  => $self->id,
		alias               => $self->alias,
		generation_name     => $self->generation_name,
		legacy_product_name => $self->legacy_product_name,
		name                => $self->name,
		prefix              => $self->prefix,
		profile             => $self->profile,
		sku                 => $self->sku,
		specification       => $self->specification,
		vendor              => $self->vendor,
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
