package Conch::DB::Util;

use v5.26;
use warnings;
use experimental 'signatures';

use Path::Tiny;
use List::Util 'maxstr';

=pod

=head1 NAME

Conch::DB:::Util - utility functions for working with the Conch database

=head1 METHODS

=head2 get_credentials

Given a database configuration hashref (such as that extracted from F<conch.conf> at the
appropriate hash key), return the credentials and connection options suitable for passing to
L<Conch::DB> for both read-write and read-only connections.

returns a hashref containing keys:

    dsn
    username
    password
    options
    ro_username
    ro_password

Overrides are accepted from the following environment variables:

    POSTGRES_USER
    POSTGRES_PASSWORD

=cut

sub get_credentials ($config, $log = Mojo::Log->new) {
    my ($dsn, $username, $password) = $config->@{qw(dsn username password)};

    if (not $dsn) {
        my $message = 'Your conch.conf is out of date. Please update it following the format in conch.conf.dist';
        $log->fatal($message);
        die $message;
    }

    my ($ro_username, $ro_password) = $config->@{qw(ro_username ro_password)};
    if (not $ro_username) {
        $log->info('read-only database credentials not provided; falling back to main credentials');
        ($ro_username, $ro_password) = ($username, $password);
    }

    # allow overrides from the environment
    $username = $ENV{POSTGRES_USER} // $username;
    $password = $ENV{POSTGRES_PASSWORD} // $password;
    $ro_username = $ENV{POSTGRES_USER} // $ro_username;
    $ro_password = $ENV{POSTGRES_PASSWORD} // $ro_password;

    my $options = {
        AutoCommit          => 1,
        AutoInactiveDestroy => 1,
        PrintError          => 0,
        PrintWarn           => 0,
        RaiseError          => 1,
        ($config->{options} // {})->%*,
    };

    return +{
        dsn => $dsn,
        username => $username,
        password => $password,
        options => $options,
        ro_username => $ro_username,
        ro_password => $ro_password,
    };
}

=head2 get_postgres_version

Retrieves the current running version of postgres.

=cut

sub get_postgres_version ($schema) {
    my $pgsql_version = $schema->storage->dbh_do(sub ($storage, $dbh) {
        my ($v) = $dbh->selectrow_array('select version()');
        return $v;
    });
}

=head2 get_migration_level

Returns as a tuple the number of the latest database migration that has been applied, and the
latest migration file found on disk.

Note that the migration level retrieved from the database does *not* have leading zeroes.

=cut

sub get_migration_level ($schema) {
    my $latest_migration = $schema->resultset('migration')->get_column('id')->max // 0;
    my $expected_latest_migration = maxstr(map m{^sql/migrations/(\d+)-}g, glob('sql/migrations/*.sql'));
    return ($latest_migration, $expected_latest_migration);
}

=head2 initialize_db

Initialize an empty database with the conch user and role and create empty tables.

=cut

sub initialize_db ($schema) {
    my $debug = $schema->storage->debug;
    my $do = $debug
        ? sub { my $dbh = shift; say STDERR @_; $dbh->do(@_) }
        : sub { shift->do(@_) };

    $schema->storage->dbh_do(sub ($storage, $dbh, @args) {
        $dbh->$do('CREATE ROLE conch LOGIN');
        $dbh->$do('CREATE DATABASE conch OWNER conch');
        say STDERR 'loading sql/schema.sql' if $debug;
        $dbh->do(path('sql/schema.sql')->slurp_utf8) or die 'SQL load failed in sql/schema.sql';
        $dbh->$do('RESET search_path');  # go back to "$user", public

        state $migration = maxstr(map m{^sql/migrations/(\d+)-}g, glob('sql/migrations/*.sql'));
        $dbh->$do('insert into migration (id) values (?)', {}, $migration);
    });
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
# vim: set ts=4 sts=4 sw=4 et :
