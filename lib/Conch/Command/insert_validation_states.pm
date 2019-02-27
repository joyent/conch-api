package Conch::Command::insert_validation_states;

=pod

=head1 NAME

insert_validation_states - insert new validation_state records from old device_validate data

=head1 SYNOPSIS

    bin/conch insert_validation_states [long options...] inputfile.csv

        --help  print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;
use Text::CSV_XS;

has description => 'Insert new validation_state records from old device_validate data';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {

    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'insert_validation_states %o inputfile.csv',
        [],
        [ 'help', 'print usage message and exit', { shortcircuit => 1 } ],
    );

    my $start_time = time;
    my $not_found = 0;
    my $infile = shift @ARGV or die $opt->usage;

    # do work inside a transaction, in case there is a problem...
    my $schema = $self->app->schema;

    my $rows_created = $schema->txn_do(sub {
        my $csv = Text::CSV_XS->new({ binary => 1, eol => $/ });
        open my $fh, $infile or die "cannot open $infile for reading: $!";

        # document has no header line, and lines look like:
        # uuid,some-serial-number,1,2018-03-31 19:58:49.604249-04
        # i.e. report_id, device_id, device_validate.validation->'status', created

        my $device_report_rs = $schema->resultset('device_report');
        my $validation_state_rs = $schema->resultset('validation_state');

        my $rows_created = 0;
        my %exists_report_ids;
        my %not_exists_report_ids;

        my $validation_plan = $schema->resultset('validation_plan')->update_or_create({
            name => 'Conch device_validate results placeholder',
            description => 'plan to track all backfilled validation_state rows from the old device_validate table',
        });
        my $validation_plan_id = $validation_plan->id;

        while (my $row = $csv->getline($fh)) {
            my ($report_id, $device_id, $bool_status, $timestamp) = $row->@*;

            # we will only create one validation_state record per report, using the
            # min(validation_state_enum) of all the reports we found.

            # status was originally a boolean. we turn it in a validation_status_enum:
            # null -> error
            # 0, false -> fail
            # 1, true -> pass
            my $status =
                !defined($bool_status) ? 'error'
              : $bool_status ? 'pass'
              : 'fail';

            # already searched for this report_id; it doesn't exist.
            if (exists $not_exists_report_ids{$report_id}) {
                next;
            }
            # already created a validation_state entry for this report_id; update it.
            elsif (exists $exists_report_ids{$report_id}
                    or $validation_state_rs->search({
                        device_id => $device_id,
                        device_report_id => $report_id,
                        validation_plan_id => $validation_plan_id,
                    })->exists) {
                # update existing record
                $validation_state_rs->search({
                        device_id => $device_id,
                        device_report_id => $report_id,
                        validation_plan_id => $validation_plan_id,
                    })
                    ->update({
                        status => \[ q{least(?, status)}, $status ],
                        completed => \[ q{greatest(?, completed)}, $timestamp],
                    });
                $exists_report_ids{$report_id} = ();
            }
            # check if this report_id exists (and has the right device_id).
            elsif (not $device_report_rs->search({ device_id => $device_id, id => $report_id })->exists) {
                ++$not_found;
                $not_exists_report_ids{$report_id} = ();
                next;
            }
            # hurrah, the report exists and we haven't created a record for it yet!
            else {
                $validation_state_rs->create({
                    device_id => $device_id,
                    device_report_id => $report_id,
                    validation_plan_id => $validation_plan_id,
                    status => $status,
                    completed => $timestamp,
                    # note: no validation_state_members or validation_results.
                });

                $exists_report_ids{$report_id} = ();
                ++$rows_created;
            }
        }

        close $fh;
        return $rows_created;
    });

    my $end_time = time;
    my $elapsed = int($end_time - $start_time);
    my $hours = $elapsed / 60 / 60;
    my $minutes = $elapsed - ($hours * 60 * 60) / 60;
    my $seconds = $elapsed - ($hours * 60 * 60) - ($minutes * 60);

    say 'done. device_report entries not found: '.$not_found,
        ', validation_state rows created: '.$rows_created,
        '; elapsed time: '.$hours.'h'.$minutes.'m'.$seconds.'s';
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
