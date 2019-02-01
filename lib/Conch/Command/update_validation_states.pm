package Conch::Command::update_validation_states;

=pod

=head1 NAME

update_validation_states - set validation_state.device_report_id

=head1 SYNOPSIS

    bin/conch update_validation_states [long options...]

        --help  print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;

has description => 'Set validation_state.device_report_id in all historical records';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {

    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'update_validation_states %o',
        [],
        [ 'help',           'print usage message and exit', { shortcircuit => 1 } ],
    );

    say Conch::Time->now, '  working...';

    # do work inside a transaction, in case there is a problem...
    my $schema = $self->app->schema;
    $schema->txn_do(sub {
        $schema->storage->dbh_do(sub {
            my ($storage, $dbh) = @_;

            my $rows = $dbh->do(<<'SQL');
update validation_state
     set device_report_id =
         (select device_report.id from device_report
             join device on device.id = validation_state.device_id
             where device_report.created <= validation_state.completed
             order by device_report.created desc limit 1)
     where device_report_id is null and validation_state.completed is not null;
SQL

            say Conch::Time->now, '  ', $rows, ' complete validation_state rows updated.';

            $rows = $dbh->do(<<'SQL');
update validation_state
     set device_report_id =
         (select device_report.id from device_report
             join device on device.id = validation_state.device_id
             where device_report.created <= validation_state.created
             order by device_report.created desc limit 1)
where device_report_id is null and validation_state.completed is null;
SQL

            say Conch::Time->now, '  ', $rows, ' incomplete validation_state rows updated.';
        });
    });

    say Conch::Time->now, '  done.  Rows remaining with null device_report_id: ',
        $self->app->db_validation_states->search({ device_report_id => undef })->count;
    say 'You may now run the deployment migration that sets validation_state.device_report_id to not-nullable.';
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
