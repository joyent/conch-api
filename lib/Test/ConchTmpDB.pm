package Test::ConchTmpDB;
use v5.20;
use warnings;

use Test::PostgreSQL;
use DBI;
use Conch::DB;
use Path::Tiny;

use Exporter 'import';
our @EXPORT_OK = qw( mk_tmp_db pg_dump );	 # TODO: do not export OO methods

=head1 NAME

Test::ConchTmpDB

=over

=item mk_tmp_db()

Create a new ephemeral Postgres instance and load extensions, the base schema,
and all migrations. Returns the object from L<Test::PostgreSQL>.

TODO: move this to Test::Conch?

=back

=cut

sub mk_tmp_db {
	my $class = shift // __PACKAGE__;

	my $pgtmp = Test::PostgreSQL->new();
	die $Test::PostgreSQL::errstr if not $pgtmp;

	my $schema = $class->schema($pgtmp);

	$schema->storage->dbh_do(sub {
		my ($storage, $dbh, @args) = @_;
		$dbh->do('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";') or die;
		$dbh->do('CREATE EXTENSION IF NOT EXISTS "pgcrypto";') or die;

		$dbh->do($_->slurp_utf8) or BAIL_OUT("Test SQL load failed in $_")
			foreach sort (path('sql/migrations')->children(qr/\.sql/));
	});

	# Add a user so we can log in. User: conch; Password: conch;
    $schema->resultset('UserAccount')->create({
        name => 'conch',
        email => 'conch@conch.joyent.us',
        password_hash => '{CRYPT}$2a$04$h963P26i4rTMaVogvA2U7ePcZTYm2o0gfSHyxaUCZSuthkpg47Zbi',
        is_admin => 1,
    }) or die;

	$schema->storage->dbh_do(sub {
		my ($storage, $dbh, @args) = @_;
		$dbh->do(
			q|
		insert into user_workspace_role(user_id,workspace_id,role) values(
		  (select id from user_account where name='conch' limit 1),
		  (select id from workspace where name='GLOBAL' limit 1),
		  'admin'
		); |
		) or die;
	});

	# TODO: return a DBIx::Class::Schema instead.
	return $pgtmp;
}

=head2 make_full_db

	my $pg = Test::ConchTmpDB->make_full_db($path);

Generate a test database using all sql files in the given path. Path defaults to C<sql/test/>

TODO: move this to Test::Conch::Datacenter?

=cut

sub make_full_db {
	my $class = shift;
	my $path = shift || "sql/test/";

	my $pg = $class->mk_tmp_db;
	my $schema = $class->schema($pg);

	$schema->storage->dbh_do(sub {
		my ($storage, $dbh, @args) = @_;
		$dbh->do($_->slurp_utf8) or die "Failed to load sql file: $_"
			foreach sort (path($path)->children(qr/\.sql/));
	});

	# TODO: return a DBIx::Class::Schema instead.
	return $pg;
}

=head2 schema

Given the return value from C<mk_tmp_db> or C<make_full_db>, returns a DBIx::Class::Schema
object just like C<< $c->schema >> or C<< $conch->schema >> in the application.

=cut

sub schema {
	my $class = shift;
	my $pgsql = shift;	# this is generally a Test::PostgreSQL

	my $schema = Conch::DB->connect(sub {
		# we could Mojo::Pg->new(..), but we don't have the pg_uri it wants.
		DBI->connect($pgsql->dsn, undef, undef, {
			# defaults used in Mojo::Pg
			AutoCommit          => 1,
			AutoInactiveDestroy => 1,
			PrintError          => 0,
			PrintWarn           => 0,
			RaiseError          => 1
		});
	});
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
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
