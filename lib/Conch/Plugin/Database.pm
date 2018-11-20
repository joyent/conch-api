package Conch::Plugin::Database;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Conch::Pg;
use Conch::DB ();
use Lingua::EN::Inflexion 'noun';
use Try::Tiny;

=pod

=head1 NAME

Conch::Plugin::Database

=head1 DESCRIPTION

Sets up the database and provides convenient accessors to it.

=head1 HELPERS

=cut

sub register ($self, $app, $config) {

    # Conch::Pg = legacy database access; will be removed soon.
    # for now we use Mojo::Pg to parse the pg connection uri.
    my $mojo_pg = Conch::Pg->new($config->{pg})->{pg};
    my ($dsn, $username, $password, $options) = map { $mojo_pg->$_ } qw(dsn username password options);


=head2 schema

Provides read/write access to the database via L<DBIx::Class>.  Returns a L<Conch::DB> object
that persists for the lifetime of the application.

=cut

    $app->helper(schema => sub {
        state $_rw_schema = Conch::DB->connect(
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

    $app->helper(ro_schema => sub {
        state $_ro_schema = Conch::DB->connect(
            # we wrap up the DBI connection attributes in a subref so
            # DBIx::Class doesn't warn about AutoCommit => 0 being a bad idea.
            sub {
                DBI->connect(
                    $dsn, $username, $password,
                    {
                        $options->%*,
                        ReadOnly        => 1,
                        AutoCommit      => 0,
                    },
                );
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
            $c->app->log->debug('rolled back transaction');
            if ($exception !~ /^rollback/) {
                $c->app->log->error($_);
                my ($error) = split(/\n/, $exception, 2);
                $c->status($c->res->code // 400, { error => $error });
            }
            $c->rendered(400) if not $c->res->code;
            return;
        };
    });

    # verify that we are running the version of postgres we expect...
    my $version = $app->schema->storage->dbh_do(sub ($storage, $dbh) {
        my ($v) = $dbh->selectrow_array('select version()');
        return $v;
    });

    $app->log->debug("Running $version");
    $app->log->fatal("Running $version, expected 9.6!") if $version !~ /PostgreSQL 9\.6/;

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
