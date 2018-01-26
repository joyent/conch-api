package Conch::Model::WorkspaceRole;
use Mojo::Base -base, -signatures;

use aliased 'Conch::Class::WorkspaceRole';

has 'pg';

sub list ( $self ) {
	$self->pg->db->select( 'role', undef )
		->hashes->map( sub { WorkspaceRole->new(shift) } )->to_array;
}

sub lookup_by_name ( $self, $role_name ) {
	my $ret =
		$self->pg->db->select( 'role', undef, { name => $role_name } )->hash;
	return undef unless $ret;
	return WorkspaceRole->new($ret);
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

