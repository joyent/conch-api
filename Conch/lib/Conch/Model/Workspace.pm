package Conch::Model::Workspace;
use Mojo::Base -base, -signatures;

use Attempt qw(try fail success when_defined);

use aliased 'Conch::Class::Workspace';

has 'pg';

sub lookup_by_name ( $self, $name ) {
  when_defined { Workspace->new(shift) }
  $self->pg->db->select( 'workspace', undef, { name => $name } )->hash;
}

sub add_user_to_workspace ( $self, $user_id, $ws_id, $role_id ) {

  # On conflict, set the role for the user
  $self->pg->db->query(
    q{
      INSERT INTO user_workspace_role (user_id, workspace_id, role_id)
      SELECT ?, ?, ?
      ON CONFLICT (user_id, workspace_id) DO UPDATE
        SET role_id = excluded.role_id
    }, $user_id, $ws_id, $role_id
  )->rows;
}

# Create a sub-workspace with the same role as the parent workspace
sub create_sub_workspace ( $self, $user_id, $parent_id, $role_id, $name,
  $description )
{
  my $db = $self->pg->db;

  my $attempt = try {
    my $tx       = $db->begin;
    my $subws_id = $db->insert(
      'workspace',
      {
        name                => $name,
        description         => $description,
        parent_workspace_id => $parent_id
      },
      { returning => 'id' }
    )->hash->{id};
    $db->insert(
      'user_workspace_role',
      {
        user_id      => $user_id,
        workspace_id => $subws_id,
        role_id      => $role_id
      }
    );
    my $role_name =
      $db->select( 'role', 'name', { id => $role_id } )->hash->{name};
    $tx->commit;
    return Workspace->new(
      {
        id                  => $subws_id,
        name                => $name,
        description         => $description,
        role                => $role_name,
        role_id             => $role_id,
        parent_workspace_id => $parent_id
      }
    );
  };
  return $attempt;
}

sub get_user_workspaces ( $self, $user_id ) {
  $self->pg->db->query(
    q{
    SELECT w.id, w.name, w.description, r.name as role, r.id as role_id
    FROM workspace w
    JOIN user_workspace_role uwr
    ON w.id = uwr.workspace_id
    JOIN user_account u
    on u.id = uwr.user_id
    JOIN role r
    on r.id = uwr.role_id
    WHERE u.id = ?::uuid
    }, $user_id
  )->hashes->map( sub { Workspace->new($_) } )->to_array;
}

sub get_user_workspace ( $self, $user_id, $ws_id ) {
  when_defined { Workspace->new(shift) }
  $self->pg->db->query(
    q{
          SELECT w.id, w.name, w.description, r.name as role, r.id as role_id
          FROM workspace w
          JOIN user_workspace_role uwr
          ON w.id = uwr.workspace_id
          JOIN user_account u
          on u.id = uwr.user_id
          JOIN role r
          on r.id = uwr.role_id
          WHERE u.id = ?::uuid
            AND w.id = ?::uuid
          }, $user_id, $ws_id
  )->hash;
}

# Get all descendents of a workspace recursively
sub get_user_sub_workspaces ( $self, $user_id, $ws_id ) {
  $self->pg->db->query(
    q{
    WITH RECURSIVE subworkspace (id, name, description, parent_workspace_id) AS (
        SELECT id, name, description, parent_workspace_id
        FROM workspace w
        WHERE parent_workspace_id = ?
      UNION
        SELECT w.id, w.name, w.description, w.parent_workspace_id
        FROM workspace w, subworkspace s
        WHERE w.parent_workspace_id = s.id
    )
    SELECT subworkspace.id, subworkspace.name, subworkspace.description,
      role.name as role, role.id as role_id
    FROM subworkspace
    JOIN user_workspace_role uwr
      ON subworkspace.id = uwr.workspace_id
    JOIN role
      ON role.id = uwr.role_id
    WHERE uwr.user_id = ?
  }, $ws_id, $user_id
  )->hashes->map( sub { Workspace->new($_) } )->to_array;
}

1;
