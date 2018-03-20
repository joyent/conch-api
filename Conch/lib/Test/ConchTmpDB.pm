package Test::ConchTmpDB;

use Test::PostgreSQL;
use DBI;
use IO::All;

use Exporter 'import';
@EXPORT = qw( mk_tmp_db pg_dump );

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

	for my $file ( io->dir("sql/migrations")->sort->glob("*.sql") ) {
		$dbh->do( $file->all ) or die;
	}

	# Add a user so we can log in. User: conch; Password: conch;
	$dbh->do(
		q|
    insert into user_account(
      name,
      email,
      password_hash
    ) values(
      'conch',
      'conch@conch.joyent.us',
      '{CRYPT}$2a$04$h963P26i4rTMaVogvA2U7ePcZTYm2o0gfSHyxaUCZSuthkpg47Zbi'
    ); |
	) or die;

	$dbh->do(
		q|
    insert into user_workspace_role(user_id,workspace_id,role_id) values(
      (select id from user_account where name='conch' limit 1),
      (select id from workspace where name='GLOBAL' limit 1),
      (select id from role where name='Administrator' limit 1)
    ); |
	) or die;

	return $pgtmp;
}


=head2 make_full_db

	my $pg = Test::ConchTmpDB->make_full_db($path);

Generate a test database using all sql files in the given path. Path defaults to C<../sql/test/>

=cut

sub make_full_db {
	my $class = shift;
	my $path = shift || "../sql/test/";
	my $pg = $class->mk_tmp_db;
	my $dbh = DBI->connect($pg->dsn);
	for my $file ( io->dir($path)->sort->glob("*.sql") ) {
		$dbh->do($file->all) or die "Failed to load sql file: $file";
	}
	return $pg;
}


=head2 pg_dump

	my $txt = pg_dump($pgtmp);

Get the contents of a pg_dump called against the test database

=cut

sub pg_dump {
	my $pg = shift;
	my $uri = $pg->uri;
	my $txt = `pg_dump --column-inserts --data-only --no-owner $uri 2>/dev/null`;
	return $txt;
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

