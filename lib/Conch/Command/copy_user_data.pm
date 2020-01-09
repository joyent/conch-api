package Conch::Command::copy_user_data;

=pod

=head1 NAME

copy_user_data - copy user data (user records and authentication tokens) between databases

=head1 SYNOPSIS

    bin/conch copy_user_data [long options...]

        --from        name of database to copy from (required)
        --to          name of database to copy to (required)
        -n --dry-run  dry-run (no changes are made)

        --help        print usage message and exit

=head1 DESCRIPTION

Use this script after restoring a database backup to a separate database, before swapping it into place to go live. e.g.:

    : on db server
    psql -U postgres --command="create database conch_prod_$(date '+%Y%m%d) owner conch"
    pg_restore -U postgres -d conch_prod_$(date '+%Y%m%d') -j 3 -v /path/to/$(date '+%Y-%m-%d')T00:00:00Z; date

    psql -U postgres --command="create database conch_staging_$(date '+%Y%m%d')_user_bak owner conch"
    psql -U postgres conch_staging_$(date '+%Y%m%d')_user_bak --command="CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public"
    pg_dump -U conch  --inserts -t user_account -t user_session_token conch | psql -U conch conch_staging_$(date '+%Y%m%d')_user_bak
    carton exec bin/conch copy_user_data --from conch_staging_$(date '+%Y%m%d')_user_bak --to conch_prod_$(date '+%Y%m%d')

    : on api server
    svcadm disable conch

    : on db server
    psql -U postgres --command="alter database conch rename to conch_staging_$(date '+%Y%m%d')_bak; alter database conch_prod_$(date '+%Y%m%d') rename to conch"

    : on api server
    svcadm enable conch

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;
use Try::Tiny;
use Data::Page;

has description => 'Copy user records and authentication tokens between databases';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {
    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'copy_user_data %o',
        [ 'from=s',         'name of database to copy from', { required => 1 } ],
        [ 'to=s',           'name of database to copy to', { required => 1 } ],
        [ 'dry-run|n',      'dry-run (no changes are made)' ],
        [],
        [ 'help',           'print usage message and exit', { shortcircuit => 1 } ],
    );

    my $app = $self->app;
    my $app_name = $app->moniker.'-copy_user_data-'.$app->version_tag.' ('.$$.')';
    my $db_credentials = Conch::DB::Util::get_credentials($app->config->{database}, $app->log);

    my ($from_schema, $to_schema) = map Conch::DB->connect(
            $db_credentials->{dsn} =~ s/(?<=dbi:Pg:dbname=)([^;]+)(?=;host=)/$_/r,
            $db_credentials->@{qw(username password)},
            +{
                $db_credentials->{options}->%*,
                on_connect_do => [ q{set application_name to '}.$app_name.q{'} ],
            },
        ), $opt->from, $opt->to;

    my $from_user_rs = $from_schema->resultset('user_account')->hri;
    my $to_user_rs = $to_schema->resultset('user_account');

    if ($opt->dry_run) {
        say '# '.$from_user_rs->count.' user records would be inserted or updated.';
    }
    else {
        my ($updated, $created) = (0,0);
        while (my $user_data = $from_user_rs->next) {
            # update_or_create calls update($data) which calls set_inflated_columns,
            # which will corrupt password entries
            my $to_rs = $to_user_rs->hri->search({ id => $user_data->{id} });
            if ($to_rs->exists) {
                $to_rs->update($user_data);
                ++$updated;
            }
            else {
                my $row = $to_user_rs->new_result({});
                # we do not use set_columns, because DBIx::Class::PassphraseColumn
                # inappropriately wraps it to encrypt the data.
                $row->store_column($_, $user_data->{$_}) for keys %$user_data;
                $row->insert;
                ++$created;
            }
        }
        say '# user_account: '.$created.' rows inserted, '.$updated.' updated.';
    }

    my $from_token_rs = $from_schema->resultset('user_session_token')->hri;
    my $to_token_rs = $to_schema->resultset('user_session_token');

    if ($opt->dry_run) {
        say '# '.$from_token_rs->count.' user_session_token rows would be inserted.';
    }
    else {
        my $count = $from_token_rs->count;
        $to_token_rs->delete;
        $to_token_rs->populate([ $from_token_rs->all ]);
        say '# user_session_token: '.$count.' rows inserted (all previous rows removed)';
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
