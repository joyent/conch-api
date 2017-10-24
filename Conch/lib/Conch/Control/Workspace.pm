package Conch::Control::Workspace;

use strict;
use warnings;
use Log::Any '$log';

use Data::Printer;
use Mojo::Pg;
use Mojo::Pg::Database;

use Conch::Control::User qw( create_integrator_password hash_password );

use Exporter 'import';
our @EXPORT = qw(
  get_user_workspaces get_user_workspace create_sub_workspace get_sub_workspaces
  invite_user_to_workspace workspace_users
);

sub get_user_workspaces {
  my ( $schema, $user_id ) = @_;
  my $workspaces = $schema->storage->dbh_do(
    sub {
      my ( $storage, $dbh ) = @_;
      my $db = Mojo::Pg::Database->new( dbh => $dbh );
      return $db->query(
        q{
        SELECT w.id, w.name, w.description, r.name as role
        FROM workspace w
        JOIN user_workspace_role uwr
          ON w.id = uwr.workspace_id
        JOIN user_account u
          on u.id = uwr.user_id
        JOIN role r
          on r.id = uwr.role_id
        WHERE u.id = ?::uuid
      }, $user_id
      )->hashes;
    }
  );
  return $workspaces->to_array;
}

sub get_user_workspace {
  my ( $schema, $user_id, $ws_id ) = @_;
  my $workspace = $schema->storage->dbh_do(
    sub {
      my ( $storage, $dbh ) = @_;
      my $db = Mojo::Pg::Database->new( dbh => $dbh );
      return $db->query(
        q{
        SELECT w.id, w.name, w.description, r.name as role
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
  );
  return $workspace;
}

# Create a sub-workspace with the same role as the parent workspace
sub create_sub_workspace {
  my ( $schema, $user_id, $ws_id, $name, $description ) = @_;
  my $subworkspace = $schema->storage->dbh_do(
    sub {
      my ( $storage, $dbh ) = @_;
      my $db = Mojo::Pg::Database->new( dbh => $dbh, pg => Mojo::Pg->new );

      my $tx      = $db->begin;
      my $role_id = $db->select( 'user_workspace_role', 'role_id',
        { user_id => $user_id, workspace_id => $ws_id } )->hash->{role_id};
      my $subws_id = $db->insert(
        'workspace',
        {
          name                => $name,
          description         => $description,
          parent_workspace_id => $ws_id
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
      $tx->commit;
      return {
        id          => $ws_id,
        name        => $name,
        description => $description,
        role        => 'Administrator'
      };
    }
  );
  return $subworkspace;
}

sub get_sub_workspaces {
  my ( $schema, $user_id, $ws_id, $name, $description ) = @_;
  my $subworkspaces = $schema->storage->dbh_do(
    sub {
      my ( $storage, $dbh ) = @_;
      my $db = Mojo::Pg::Database->new( dbh => $dbh, pg => Mojo::Pg->new );
      $db->query(
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
          role.name as role
        FROM subworkspace
        JOIN user_workspace_role uwr
          ON subworkspace.id = uwr.workspace_id
        JOIN role
          ON role.id = uwr.role_id
        WHERE uwr.user_id = ?
      }, $ws_id, $user_id
      )->hashes->to_array;
    }
  );
  return $subworkspaces;
}

# TODO: Send an email to the user when they're created or invited to the workspace
# Sets the user role if the user is already assigned to the workspace
sub invite_user_to_workspace {
  my ( $schema, $ws_id, $email, $role ) = @_;
  return $schema->storage->dbh_do(
    sub {
      my ( $storage, $dbh ) = @_;
      my $db = Mojo::Pg::Database->new( dbh => $dbh, pg => Mojo::Pg->new );
      my $user = $db->select(
        'user_account',
        [ 'id', 'name', 'email' ],
        { email => $email }
      )->hash;
      unless ( defined $user ) {
        my $password      = create_integrator_password();
        my $password_hash = hash_password($password);
        $user = $db->insert(
          'user_account',
          {
            name          => $email,
            email         => $email,
            password_hash => $password_hash
          },
          { returning => [ 'id', 'name', 'email' ] }
        );

        # TODO Email the password or a password reset token link
        $log->alert("New user password: $password");
      }
      # On conflict, set the role for the user
      $db->query( q{
        INSERT INTO user_workspace_role (user_id, workspace_id, role_id)
        SELECT ?, ?, role.id
        FROM role
        WHERE role.name = ?
        ON CONFLICT (user_id, workspace_id) DO UPDATE
          SET role_id = excluded.role_id
        }, $user->{id}, $ws_id, $role
      );
      return {
        name => $user->{name},
        email => $user->{email},
        role => $role
      };
    }
  );
}

sub workspace_users {
  my ( $schema, $ws_id ) = @_;
  my $users = $schema->storage->dbh_do(
    sub {
      my ( $storage, $dbh ) = @_;
      my $db = Mojo::Pg::Database->new( dbh => $dbh, pg => Mojo::Pg->new );
      return $db->query( q{
        SELECT u.name, u.email, r.name as role
        FROM user_workspace_role uwr
        JOIN user_account u
        ON u.id = uwr.user_id
        JOIN role r
        on r.id = uwr.role_id
        WHERE uwr.workspace_id = ?::uuid
        }, $ws_id)->hashes;
    }
  );
  return $users->to_array;
}

1;
