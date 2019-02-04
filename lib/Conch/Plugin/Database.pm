package Conch::Plugin::Database;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Conch::Pg;
use Conch::DB ();
use Lingua::EN::Inflexion 'noun';
use Try::Tiny;
use List::Util 'maxstr';

=pod

=head1 NAME

Conch::Plugin::Database

=head1 DESCRIPTION

Sets up the database and provides convenient accessors to it.

=head1 HELPERS

=cut

sub register ($self, $app, $config) {

    my $database_config = $config->{database};
    my ($dsn, $username, $password) = $database_config->@{qw(dsn username password)};

    if (not $dsn) {
        my $message = 'Your conch.conf is out of date. Please update it following the format in conch.conf.dist';
        $app->log->fatal($message);
        die $message;
    }

    my ($ro_username, $ro_password) = $database_config->@{qw(ro_username ro_password)};
    if (not $ro_username or not $ro_password) {
        $app->log->info('read-only database credentials not provided; falling back to main credentials');
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
        ($database_config->{options} // {})->%*,
    };

    # Conch::Pg = legacy database access; will be removed soon.
    Conch::Pg->new({
        $database_config->%{qw(dsn username password)},
        $ENV{POSTGRES_USER} ? ( username => $ENV{POSTGRES_USER} ) : (),
        $ENV{POSTGRES_PASSWORD} ? ( password => $ENV{POSTGRES_PASSWORD} ) : (),
        options => $options,
    });


=head2 schema

Provides read/write access to the database via L<DBIx::Class>.  Returns a L<Conch::DB> object
that persists for the lifetime of the application.

=cut

    my $_rw_schema;
    $app->helper(schema => sub {
        return $_rw_schema if $_rw_schema;
        $_rw_schema = Conch::DB->connect(
            $dsn, $username, $password, $options,
        );
    });

=head2 rw_schema

See L</schema>; can be used interchangeably with it.

=cut

    $app->helper(rw_schema => $app->renderer->get_helper('schema'));

=head2 ro_schema

Provides (guaranteed) read-only access to the database via L<DBIx::Class>.  Returns a
L<Conch::DB> object that persists for the lifetime of the application.

Note that because of the use of C<< AutoCommit => 0 >>, database errors must be explicitly
cleared with C<< ->txn_rollback >>; see L<DBD::Pg/"ReadOnly-(boolean)">.

=cut

    my $_ro_schema;
    $app->helper(ro_schema => sub {
        if ($_ro_schema) {
            # clear the transaction of any errors, which accumulate because we have
            # AutoCommit => 0 for this connection.  Otherwise, we will get:
            # "current transaction is aborted, commands ignored until end of transaction block"
            # (as an alternative, we can turn the ReadOnly and AutoCommit flags off, and use
            # the read-only credentials to connect to the server.. but it is better to have
            # this safety here.)
            $_ro_schema->txn_rollback;
            return $_ro_schema;
        }

        # see L<DBIx::Class::Storage::DBI/DBIx::Class and AutoCommit>
        local $ENV{DBIC_UNSAFE_AUTOCOMMIT_OK} = 1;
        $_ro_schema = Conch::DB->connect(
            $dsn, $ro_username, $ro_password,
            +{
                $options->%*,
                ReadOnly    => 1,
                AutoCommit  => 0,
            },
        );
    });

=head2 db_<table>s, db_ro_<table>s

Provides direct read/write and read-only accessors to resultsets.  The table name is used in
the C<alias> attribute (see L<DBIx::Class::ResultSet/alias>).

=cut

    # db_user_accounts => $app->schema->resultset('user_account'), etc
    # db_ro_user_accounts => $app->ro_schema->resultset('user_account'), etc
    foreach my $source_name ($app->schema->sources) {
        my $plural = noun($source_name)->plural;

        $app->helper('db_'.$plural, sub {
            my $source = $_[0]->app->schema->source($source_name);
            # note that $source_name eq $source->from unless we screwed up.
            $source->resultset->search({}, { alias => $source->from });
        });

        $app->helper('db_ro_'.$plural, sub {
            my $ro_source = $_[0]->app->ro_schema->source($source_name);
            $ro_source->resultset->search({}, { alias => $ro_source->from });
        });
    }

=head2 txn_wrapper

Wraps the provided subref in a database transaction, rolling back in case of an exception.
Any provided arguments are passed to the sub, along with the invocant controller.

If the exception is not C<'rollback'> (which signals an intentional premature bailout), the
exception will be logged, and a response will be set up as an error response with the first
line of the exception.

=cut

    $app->helper(txn_wrapper => sub ($c, $subref, @args) {
        try {
            # we don't do anything else here, so as to preserve context and the return value
            # for the original caller.
            $c->schema->txn_do($subref, $c, @args);
        }
        catch {
            my $exception = $_;
            my $log = $c->can('log') ? $c->log : $c->app->log;
            $log->debug('rolled back transaction');
            if ($exception !~ /^rollback/) {
                $log->error($_);
                my ($error) = split(/\n/, $exception, 2);
                $c->status($c->res->code // 400, { error => $error });
            }
            $c->rendered(400) if not $c->res->code;
            return;
        };
    });


    # verify that we are running the version of postgres we expect...
    my $pgsql_version = $app->schema->storage->dbh_do(sub ($storage, $dbh) {
        my ($v) = $dbh->selectrow_array('select version()');
        return $v;
    });


    # at present we do all testing on 9.6 so that is the most preferred configuration, but we
    # are not aware of any issues on PostgreSQL 10.x.
    $app->log->info("Running $pgsql_version");
    my ($major, $minor) = $pgsql_version =~ /PostgreSQL (\d+)\.(\d+)\.?/;
    $minor //= 0;
    $app->log->warn("Running $pgsql_version, expected at least 9.6!") if "$major.$minor" < 9.6;


    my $latest_migration = $app->schema->storage->dbh_do(sub ($storage, $dbh) {
        my ($m) = $dbh->selectrow_array('select max(id) from migration');
        return $m // 0;
    });
    my $expected_latest_migration = maxstr(map { m{^sql/migrations/(\d+)-}g } glob('sql/migrations/*.sql'));

    $app->log->debug("Latest database migration number: $latest_migration");
    $app->log->fatal("Latest migration that has been run is $latest_migration, but latest on disk is $expected_latest_migration!") and die
        if $latest_migration != $expected_latest_migration;
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
