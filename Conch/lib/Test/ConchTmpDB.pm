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

  my $dbh = DBI->connect($pgtmp->dsn);

  $dbh->do('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";') or die;
  $dbh->do('CREATE EXTENSION IF NOT EXISTS "pgcrypto";') or die;

  open(my $fh, '<', 'sql/conch.sql');
  my $base_schema = do { local $/; <$fh> };

  $dbh->do($base_schema);

  opendir(my $dh, 'sql/migrations');
  while (readdir $dh) {
    open(my $fh, '<', "sql/migrations/$_");
    my $migration = do { local $/; <$fh> };
    $dbh->do($migration);
  };

  closedir($dh);

  return $pgtmp;
}

1;
