package Conch::Control::Workspace;

use strict;
use warnings;
use Log::Any '$log';

use Data::Printer;
use Mojo::Pg;
use Mojo::Pg::Database;

use Exporter 'import';
our @EXPORT = qw( get_user_workspaces get_user_workspace create_sub_workspace );

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
  $schema->storage->debug(1);
  my $subworkspace = $schema->storage->dbh_do(
    sub {
      my ( $storage, $dbh ) = @_;
      my $db = Mojo::Pg::Database->new( dbh => $dbh, pg => Mojo::Pg->new );
      my $tx = $db->begin;
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

1;
