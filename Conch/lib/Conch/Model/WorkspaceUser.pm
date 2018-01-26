package Conch::Model::WorkspaceUser;
use Mojo::Base -base, -signatures;

use aliased 'Conch::Class::WorkspaceUser';

has 'pg';

sub workspace_users ( $self, $ws_id ) {
	$self->pg->db->query(
		q{
      SELECT u.name, u.email, r.name as role
      FROM user_workspace_role uwr
      JOIN user_account u
        ON u.id = uwr.user_id
      JOIN role r
        on r.id = uwr.role_id
      WHERE uwr.workspace_id = ?::uuid
      }, $ws_id
	)->hashes->map( sub { WorkspaceUser->new($_) } )->to_array;
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

