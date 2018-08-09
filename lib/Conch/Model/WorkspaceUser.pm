=pod

=head1 NAME

Conch::Model::WorkspaceUser

=head1 METHODS

=cut
package Conch::Model::WorkspaceUser;
use Mojo::Base -base, -signatures;

use Conch::Class::WorkspaceUser;
use Conch::Pg;

=head2 workspace_users

Retrieve list users assigned to a workspace.

=cut
sub workspace_users ( $self, $ws_id ) {
	Conch::Pg->new->db->query(
		q{
      SELECT u.name, u.email, r.name as role
      FROM user_workspace_role uwr
      JOIN user_account u
        ON u.id = uwr.user_id
      JOIN role r
        on r.id = uwr.role_id
      WHERE uwr.workspace_id = ?::uuid
      }, $ws_id
	)->hashes->map( sub { Conch::Class::WorkspaceUser->new($_) } )->to_array;
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
