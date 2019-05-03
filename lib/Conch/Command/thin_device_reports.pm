package Conch::Command::thin_device_reports;

=pod

=head1 NAME

thin_device_reports - remove unwanted device reports

=head1 SYNOPSIS

    bin/conch thin_device_reports [long options...]

        --help  print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;
use Try::Tiny;
use Data::Page;

has description => 'remove unwanted device reports';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

has 'dry_run';

sub run ($self, @opts) {
    # if the user needs to ^C, print the post-processing statistics before exiting.
    local $SIG{INT} = sub {
        say "\naborting! We now have this many records:";
        $self->_print_stats;
        exit;
    };

    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'thin_device_reports %o',
        [ 'dry-run|n',      'dry-run (no changes are made)' ],
        [],
        [ 'help',           'print usage message and exit', { shortcircuit => 1 } ],
    );

    $self->dry_run($opt->dry_run);

    say 'at start, we have this many records:';
    $self->_print_stats;

    # consider each device, oldest devices first, in pages of 100 rows each
    my $device_rs = ($self->dry_run ? $self->app->db_ro_devices : $self->app->db_devices)
        ->active
        ->rows(100)
        ->page(1)
        ->order_by('created');

    my ($device_count, $device_reports_deleted, $validation_results_deleted) = (0)x3;

    foreach my $page (1 .. $device_rs->pager->last_page) {
        $device_rs = $device_rs->page($page);
        while (my $device = $device_rs->next) {
            # we process each device's reports in a separate transaction,
            # so we can abort and resume without redoing everything all over again
            try {
                my @deleted = $self->app->schema->txn_do(sub {
                    $self->_process_device($device);
                });
                ++$device_count;
                $device_reports_deleted += $deleted[0];
                $validation_results_deleted += $deleted[1];
            }
            catch {
                if (/Rollback failed/) {
                    local $@ = $_;
                    die;    # propagate the error
                }
                print STDERR "\n", 'aborted processing of device '.$device->id.': ', $_, "\n";
            };
        }
    }

    say "\n$device_count devices processed.";
    say $device_reports_deleted.' device_reports deleted.' if $device_reports_deleted;
    say $validation_results_deleted.' validation_results deleted.' if $validation_results_deleted;

    say 'at finish, we have this many records:';
    $self->_print_stats;
}

sub _print_stats ($self) {
    say 'device_report:           ', $self->app->db_ro_device_reports->count;
    say 'validation_state:        ', $self->app->db_ro_validation_states->count;
    say 'validation_state_member: ', $self->app->db_ro_validation_state_members->count;
    say 'validation_result:       ', $self->app->db_ro_validation_results->count;
}

sub _process_device ($self, $device) {
    my $report_count = 0;
    print 'device id ', $device->id, ': ';

    # Consider the validation status of all reports, oldest first, in pages of 100 rows each.
    # Valid reports with no validation results are considered to be a 'pass', i.e. eligible for
    # deletion.
    my $device_report_rs = $self->app->db_device_reports
        ->search({ 'device_report.device_id' => $device->id })
        ->columns('device_report.id')
        ->with_report_status
        ->order_by({ -asc => 'device_report.created' })
        ->rows(100)
        ->page(1)
        ->hri;

    # we only delete reports when we are done, so we can safely iterate through reports
    # without the pages changing strangely
    my @delete_report_ids;

    # we push data about reports to the end as we consider each one,
    # and shift data off at the beginning when we're done
    # $report_statuses[-1]  current report
    # $report_statuses[-2]  previous report
    # $report_statuses[-3]  2 reports ago
    my @report_statuses;

    foreach my $page (1 .. $device_report_rs->pager->last_page) {
        $device_report_rs = $device_report_rs->page($page);
        while (my $device_report = $device_report_rs->next) {
            ++$report_count;
            print '.' if $report_count % 100 == 0;

            # capture information about the latest report we just fetched.
            push @report_statuses, $device_report;

            # we maintain a sliding window of (at least?) 3 reports.
            # We can consider what to do about the middle report now.

            # prevprev    previous   current     delete previous?
            # dne         dne        FAIL        0   previous report does not exist
            # dne         dne        PASS        0   previous report does not exist
            # dne         FAIL       FAIL        0   keep first
            # dne         FAIL       PASS        0   keep first
            # dne         PASS       FAIL        0   keep first
            # dne         PASS       PASS        0   keep first
            # FAIL        FAIL       FAIL        0   keep reports that fail
            # FAIL        FAIL       PASS        0   keep reports that fail
            # FAIL        PASS       FAIL        0   keep first pass after a failure
            # FAIL        PASS       PASS        0   keep first pass after a failure
            # PASS        FAIL       FAIL        0   keep reports that fail
            # PASS        FAIL       PASS        0   keep reports that fail
            # PASS        PASS       FAIL        0   last pass before a failure
            # PASS        PASS       PASS        1

            # we only delete the previous report (index [-2]) iff:
            # - the current report was a pass
            # - the previous exists and was a pass
            # - the previous-previous exists and was a pass

            push @delete_report_ids, $report_statuses[-2]{id}
                if $report_statuses[-1]{status} eq 'pass'
                    and $report_statuses[-2] and $report_statuses[-2]{status} eq 'pass'
                    and $report_statuses[-3] and $report_statuses[-3]{status} eq 'pass';

            # forget about the oldest report if we are watching at least 3.
            shift @report_statuses if $report_statuses[-3];
        }
    }

    print "\n";

    my ($device_reports_deleted, $validation_results_deleted) = (0,0);

    if ($self->dry_run) {
        say 'Would delete ', scalar(@delete_report_ids), ' reports for device id ', $device->id,
            ' out of ', $report_count, ' examined.';
    }
    else {
        # delete all reports that we identified for deletion
        # this may also cause cascade deletes on validation_state, validation_state_member.
        say 'deleting ', scalar(@delete_report_ids), ' reports for device id ', $device->id,
            ' out of ', $report_count, ' examined...';

        # delete reports 100 records at a time
        my $pager = Data::Page->new(scalar @delete_report_ids, 100);
        for ($pager->first_page .. $pager->last_page) {
            my @ids = $pager->splice(\@delete_report_ids);
            last if not @ids;
            $pager->current_page($pager->current_page + 1);

            $device_reports_deleted += $device
                ->search_related('device_reports', { id => { -in => \@ids } })
                ->delete;
        }

        # delete all newly-orphaned validation_result rows for this device
        $validation_results_deleted = $device->search_related('validation_results',
            { 'validation_state_members.validation_state_id' => undef },
            { join => 'validation_state_members' },
        )->delete;
    }

    print "\n";

    return ($device_reports_deleted, $validation_results_deleted);
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
