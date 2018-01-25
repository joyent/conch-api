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
