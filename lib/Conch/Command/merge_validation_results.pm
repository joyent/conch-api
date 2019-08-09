package Conch::Command::merge_validation_results;

=pod

=head1 NAME

merge_validation_results - collapse duplicate validation_result rows together

=head1 SYNOPSIS

    bin/conch merge_validation_results [long options...]

        -n --dry-run  dry-run (no changes are made)
        --help        print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;
use Try::Tiny;
use Data::Page;

has description => 'Collapse duplicate validation_result rows together';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

has 'dry_run';

sub run ($self, @opts) {
    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'merge_validation_results %o',
        [ 'dry-run|n',      'dry-run (no changes are made)' ],
        [],
        [ 'help',           'print usage message and exit', { shortcircuit => 1 } ],
    );

    # ACHTUNG! only run this after migration 92 is done,
    # because otherwise these queries will take even longer.

    $self->dry_run($opt->dry_run);

    # enable autoflush
    my $prev = select(STDOUT); $|++; select($prev);

    say Conch::Time->now, '  working'.($self->dry_run ? ' (in dry-run mode)' : '').'...';
    my $schema = ($self->dry_run ? $self->app->ro_schema : $self->app->schema);

    say 'At start, there are '
        .$schema->resultset('validation_result')->count
        .' validation_result rows.';
    say '';

    my ($validation_results_deleted, $device_count) = (0)x2;

    # consider each device, oldest devices first, in pages of 100 rows each
    my $device_rs = $schema->resultset('device')
        ->active
        ->rows(100)
        ->page(1)
        ->order_by('created');

    foreach my $page (1 .. $device_rs->pager->last_page) {
        $device_rs = $device_rs->page($page);
        while (my $device = $device_rs->next) {
            # we process each device's reports in a separate transaction,
            # so we can abort and resume without redoing everything all over again
            try {
                $validation_results_deleted += $schema->txn_do(sub {
                    $self->_process_device($device);
                });
                ++$device_count;
            }
            catch {
                if (/Rollback failed/) {
                    local $@ = $_;
                    die;    # propagate the error
                }
                print STDERR "\n", 'aborted processing of device ', $device->id, ': ', $_, "\n";
            };
        }
    }

    say '';
    say Conch::Time->now, '  done.';
    say '';
    say $device_count.' devices processed.';
    say $validation_results_deleted.' validation_result rows '
        .($self->dry_run ? 'would be ' : '') .'deleted.';
    say 'there are now '.$schema->resultset('validation_result')->count.' validation_result rows.';
}


sub _process_device ($self, $device) {
    print 'device id ', $device->id, ': ';

    my @grouping_cols = qw(device_id hardware_product_id validation_id message hint status category component_id result_order);

    my $schema = $self->app->schema;
    my ($group_count, $results_deleted) = (0)x2;

    # find groups of validation_result rows that share identical column
    # values that we have an index on (where new validation_states point
    # to existing rows: see the end of Conch::ValidationSystem::run_validation_plan.
    # Consider these groups in pages of 100 rows each.
    my $groups_to_merge_rs = $schema->resultset('validation_result')
        ->columns(\@grouping_cols)
        ->search(
            { device_id => $device->id },
            { '+select' => [{ count => '*', -as => 'count' }] })
        ->group_by(\@grouping_cols)
        ->as_subselect_rs
        ->search({ count => { '>' => 1 } })
        ->columns(\@grouping_cols)
        ->order_by(\@grouping_cols)
        ->rows(100)
        ->page(1)
        ->hri;

    # we go through the pages backward so we can delete rows as we go and not
    # break queries for the other pages.
    foreach my $page (reverse(1 .. $groups_to_merge_rs->pager->last_page)) {
        $groups_to_merge_rs = $groups_to_merge_rs->page($page);

        # foreach matching set,
            # iterate through all matching rows oldest-first
            # save the oldest one,
            # delete the rest, updating validation_state_member to point to the oldest.
        while (my $sample_result = $groups_to_merge_rs->next) {
            ++$group_count;
            print '.' if $group_count % 100 == 0;

            # all results in this resultset share the same values and can be collapsed down to
            # a single result row
            my $member_rs = $schema->resultset('validation_result')
                ->search({ $sample_result->%{@grouping_cols} });

            if ($self->dry_run) {
                $results_deleted += $member_rs->count - 1;
                next;
            }

            # this is the validation_result row we keep - the oldest in this group
            my $oldest_member_id = $member_rs
                ->order_by('created')
                ->rows(1)
                ->hri
                ->get_column('id')
                ->single;

            # all validation_state_members pointing to results in this group should instead
            # reference the oldest result in the group
            $schema->resultset('validation_state_member')
                ->search(
                    {
                        validation_result_id => { '!=' => $oldest_member_id },
                        (map +('validation_result.'.$_ => $sample_result->{$_}), @grouping_cols),
                    },
                    { join => 'validation_result' },
                )
                ->update({ validation_result_id => $oldest_member_id });

            # delete all the newly-orphaned validation_result rows
            # (this is safe because we don't have a cascade delete on result -> member yet)
            $results_deleted += $member_rs->search({ id => { '!=' => $oldest_member_id } })->delete;
        }
    }

    say ' '.$results_deleted.' validation_results deleted';
    return $results_deleted;
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
