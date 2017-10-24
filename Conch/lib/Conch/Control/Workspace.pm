package Conch::Control::Workspace;

use strict;
use warnings;
use Log::Any '$log';

use Data::Printer;
use Mojo::Pg::Database;

use Exporter 'import';
our @EXPORT = qw( get_user_workspaces get_user_workspace );

sub get_user_workspaces {
  my ( $schema, $user_id ) = @_;
  $schema->storage->debug(1);
  my $workspaces = $schema->storage->dbh_do(sub {
      my ($storage, $dbh) = @_;
      my $db = Mojo::Pg::Database->new(dbh => $dbh);
      return $db->query(q{
        SELECT w.id, w.name, w.description, r.name as role
        FROM workspace w
        JOIN user_workspace_role uwr
          ON w.id = uwr.workspace_id
        JOIN user_account u
          on u.id = uwr.user_id
        JOIN role r
          on r.id = uwr.role_id
        WHERE u.id = ?::uuid
      }, $user_id)->hashes;
    }
  );
  return $workspaces->to_array;
}

sub get_user_workspace {
  my ( $schema, $user_id, $ws_id) = @_;
  $schema->storage->debug(1);
  my $workspace = $schema->storage->dbh_do(sub {
      my ($storage, $dbh) = @_;
      my $db = Mojo::Pg::Database->new(dbh => $dbh);
      return $db->query(q{
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
      }, $user_id, $ws_id)->hash;
    }
  );
  return $workspace;
}

1;
