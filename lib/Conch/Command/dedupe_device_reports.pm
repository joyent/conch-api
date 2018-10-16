package Conch::Command::dedupe_device_reports;

=pod

=head1 NAME

dedupe_device_reports - remove duplicate device reports

=head1 SYNOPSIS

    dedupe_device_reports [long options...]

        --help  print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;
use Try::Tiny;

has description => 'remove duplicate device reports';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

has 'dry_run';

sub run {
    my $self = shift;

    # if the user needs to ^C, print the post-processing statistics before exiting.
    local $SIG{INT} = sub {
        say "\naborting! We now have this many records:";
        $self->_print_stats;
        exit;
    };

    local @ARGV = @_;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'dedupe_device_reports %o',
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

    my $device_count = 0;

    foreach my $page (1 .. $device_rs->pager->last_page) {

        $device_rs = $device_rs->page($page);
        while (my $device = $device_rs->next) {

            # we process each device's reports in a separate transaction,
            # so we can abort and resume without redoing everything all over again
            try {
                $self->app->schema->txn_do(sub {
                    $self->_process_device($device);
                });
                ++$device_count;
            }
            catch {
                if ($_ =~ /Rollback failed/) {
                    local $@ = $_;
                    die;    # propagate the error
                }
                print STDERR "\n", 'aborted processing of device ' . $device->id . ': ', $_, "\n";
            };
        }
    }

    say "\n$device_count devices processed.";

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

    # consider all PASSING device reports, newest first, in pages of 100 rows each
    my $device_report_rs = $device
        ->search_related('validation_states', { status => 'pass' })
        ->related_resultset('device_report')
        ->columns([ qw(id created) ])
        ->rows(100)
        ->page(1)
        ->order_by({ -desc => 'created' })
        ->hri;  # raw hashref data; do not inflate to objects or alter timestamps

    # we accumulate report ids to delete so we can safely iterate through reports
    # without the pages changing strangely
    my @delete_report_ids;

    foreach my $page (1 .. $device_report_rs->pager->last_page) {
        print "\n" if $page % 100 == 0;
        print '.';

        $device_report_rs = $device_report_rs->page($page);

        while (my $device_report = $device_report_rs->next) {
            ++$report_count;
            print '.' if $page % 100 == 0;

            # delete this report if it is identical (excluding time-series data)
            # to another report. (a *newer* report may be found if it did not have a
            # validation_state record linked to it, but usually the matching duplicate will be
            # older.)
            if ($device->related_resultset('device_reports')
                ->matches_report_id($device_report->{id})
                ->exists)
            {
                print 'x';
                push @delete_report_ids, $device_report->{id};
            }
        }
    }

    print "\n";

    if ($self->dry_run) {
        say 'Would delete ', scalar(@delete_report_ids), ' reports for device id ', $device->id,
            ' out of ', $report_count, ' examined.';
    }
    else {
        # delete all duplicate reports that we found
        # this may also cause cascade deletes on validation_state, validation_state_member.
        say 'deleting ', scalar(@delete_report_ids), ' reports for device id ', $device->id,
            ' out of ', $report_count, ' examined...';
        $device
            ->search_related('device_reports', { id => { -in => \@delete_report_ids } })
            ->delete;

        # delete all newly-orphaned validation_result rows for this device
        $device
            ->search_related('validation_results',
                { 'validation_state_members.validation_result_id' => undef },
                { join => 'validation_state_members' },
            )->delete;
    }

    print "\n";
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
