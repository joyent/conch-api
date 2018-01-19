package Test::ConchTmpDB;

use Test::PostgreSQL;
use DBI;

use Exporter 'import';
@EXPORT = qw( mk_tmp_db );

=head1 NAME

Test::ConchTmpDB

=over

=item mk_tmp_db()

Create a new ephemeral Postgres instance and load extensions, the base schema,
and all migrations. Returns the object from L<Test::PostgreSQL>.

=back

=cut

sub mk_tmp_db {

  my $pgtmp = Test::PostgreSQL->new()
    or die $Test::PostgreSQL::errstr;

  my $dbh = DBI->connect( $pgtmp->dsn );

  $dbh->do('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";') or die;
  $dbh->do('CREATE EXTENSION IF NOT EXISTS "pgcrypto";')  or die;

  open( my $fh, '<', 'sql/conch.sql' );
  my $base_schema = do { local $/; <$fh> };

  $dbh->do($base_schema);

  opendir( my $dh, 'sql/migrations' );
  my @migrations = grep { -f "sql/migrations/$_" } readdir($dh);
  for ( sort @migrations ) {
    open( my $fh, '<', "sql/migrations/$_" );
    my $migration = do { local $/; <$fh> };
    $dbh->do($migration);
  }
  closedir($dh);

  # Add a user so we can log in. User: conch; Password: conch;
  $dbh->do(q|
    insert into user_account(
      name,
      email,
      password_hash
    ) values(
      'conch',
      'conch@conch.joyent.us',
      '{CRYPT}$2a$04$h963P26i4rTMaVogvA2U7ePcZTYm2o0gfSHyxaUCZSuthkpg47Zbi'
    ); |) or die;

  $dbh->do(q|
    insert into user_workspace_role(user_id,workspace_id,role_id) values(
      (select id from user_account where name='conch' limit 1),
      (select id from workspace where name='GLOBAL' limit 1),
      (select id from role where name='Administrator' limit 1)
    ); |) or die;


  return $pgtmp;
}

1;
