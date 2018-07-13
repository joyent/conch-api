=pod

=head1 NAME

Conch::Class::Relay

=head1 METHODS

=cut

package Conch::Class::Relay;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::ToJson';

=head2 id

=head2 alias

=head2 version

=head2 ipaddr

=head2 ssh_port

=head2 created

=head2 updated

=cut

has [qw(
	id
	alias
	version
	ipaddr
	ssh_port
	created
	updated
)];

=head2 TO_JSON

=cut

sub TO_JSON {
	my $self = shift;
	{
		id       => $self->id,
		alias    => $self->alias,
		version  => $self->version,
		ipaddr   => $self->ipaddr,
		ssh_port => $self->ssh_port,
		created  => $self->created,
		updated  => $self->updated,
	}
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

