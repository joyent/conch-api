=pod

=head1 NAME

Conch::Class::Workspace

=head1 METHODS

=cut

package Conch::Class::Workspace;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::ToJson';



=head2 id

=head2 name

=head2 description

=head2 parent_workspace_id

=head2 role

=head2 role_id

=cut

has [qw( id name description parent_workspace_id role role_id )];


=head2 TO_JSON

=cut

sub TO_JSON {
	my $self = shift;
	{
		id          => $self->id,
		name        => $self->name,
		description => $self->description,
		role        => $self->role,
		parent_id   => $self->parent_workspace_id,
	}
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

