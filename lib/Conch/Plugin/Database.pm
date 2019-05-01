package Conch::Plugin::Database;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Conch::DB ();
use Lingua::EN::Inflexion 'noun';
use Try::Tiny;
use List::Util 'maxstr';
use Conch::DB::Util;

=pod

=head1 NAME

Conch::Plugin::Database

=head1 DESCRIPTION

Sets up the database and provides convenient accessors to it.

=head1 HELPERS

=cut

sub register ($self, $app, $config) {

    # hashref containing dsn, username, password, options, ro_username, ro_password
    my $db_credentials = Conch::DB::Util::get_credentials($config->{database}, $app->log);


=head2 schema

Provides read/write access to the database via L<DBIx::Class>.  Returns a L<Conch::DB> object
that persists for the lifetime of the application.

=cut

    my $_rw_schema;
    $app->helper(schema => sub {
        return $_rw_schema if $_rw_schema;
        $_rw_schema = Conch::DB->connect(
            $db_credentials->@{qw(dsn username password options)},
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
            $_ro_schema->txn_rollback if $_ro_schema->storage->connected;
            return $_ro_schema;
        }

        # see L<DBIx::Class::Storage::DBI/DBIx::Class and AutoCommit>
        local $ENV{DBIC_UNSAFE_AUTOCOMMIT_OK} = 1;
        $_ro_schema = Conch::DB->connect(
            $db_credentials->@{qw(dsn ro_username ro_password)},
            +{
                $db_credentials->{options}->%*,
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

        $app->helper('db_'.$plural, sub ($c) {
            my $source = $c->schema->source($source_name);
            # note that $source_name eq $source->from unless we screwed up.
            $source->resultset->search(undef, { alias => $source->from });
        });

        $app->helper('db_ro_'.$plural, sub ($c) {
            my $ro_source = $c->ro_schema->source($source_name);
            $ro_source->resultset->search(undef, { alias => $ro_source->from });
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
                $log->error($exception);
                my ($error) = split(/\n/, $exception, 2);
                $c->status($c->res->code // 400, { error => $error });
            }
            $c->rendered(400) if not $c->res->code;
            return;
        };
    });


    # verify that we are running the version of postgres we expect...
    my $pgsql_version = Conch::DB::Util::get_postgres_version($app->schema);
    $app->log->info("Running $pgsql_version");

    # at present we do all testing on 9.6 so that is the most preferred configuration, but we
    # are not aware of any issues on PostgreSQL 10.x.
    my ($major, $minor, $rest) = $pgsql_version =~ /PostgreSQL (\d+)\.(\d+)(\.\d+)?\b/;
    $minor //= 0;
    $app->log->warn("Running $major.$minor$rest, expected at least 9.6!") if "$major.$minor" < 9.6;


    my ($latest_migration, $expected_latest_migration) = Conch::DB::Util::get_migration_level($app->schema);
    $app->log->debug("Latest database migration number: $latest_migration");
    if ($latest_migration != $expected_latest_migration) {
        my $message = "Latest migration that has been run is $latest_migration, but latest on disk is $expected_latest_migration!";
        $app->log->fatal($message);
        die $message;
    }
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
