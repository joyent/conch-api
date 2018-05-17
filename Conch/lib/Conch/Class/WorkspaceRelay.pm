=pod

=head1 NAME

Conch::Class::WorkspaceRelay

=head1 METHODS

=cut

package Conch::Class::WorkspaceRelay;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

use Conch::Time;

with 'Conch::Class::Role::ToJson';

=head2 alias

=head2 created

=head2 devices

=head2 id

=head2 ipaddr

=head2 location

=head2 ssh_port

=head2 updated

=head2 version

=cut

has [
	qw(
		id
		alias
		created
		ipaddr
		ssh_port
		updated
		version
		devices
		location
		)
];

=head2 new

=cut

sub new {
	my $class = shift;
	my %args  = @_;
	map { $args{$_} = Conch::Time->new( $args{$_} ) if $args{$_} }
		qw(created updated);
	$class->SUPER::new(%args);
}

=head2 TO_JSON

=cut

sub TO_JSON {
	my $self = shift;
	{
		id       => $self->id,
		alias    => $self->alias,
		created  => $self->created,
		ipaddr   => $self->ipaddr,
		ssh_port => $self->ssh_port,
		updated  => $self->updated,
		version  => $self->version,
		devices  => [ map { $_->as_v1 } @{ $self->devices } ],
		location => $self->location
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
