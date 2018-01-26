=pod

=head1 NAME

Conch::Class::DatacenterRoom

=head1 METHODS

=cut

package Conch::Class::DatacenterRoom;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::JsonV1';

=head2 id

=head2 az

=head2 alias

=head2 vendor_name

=cut

has [qw( id az alias vendor_name )];



=head2 as_v1_json

=cut

sub as_v1_json {
	my $self = shift;
	{
		id          => $self->id,
		az          => $self->az,
		alias       => $self->alias,
		vendor_name => $self->vendor_name
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
