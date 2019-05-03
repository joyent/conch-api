package Conch::DB::ResultSet::DeviceReport;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use experimental 'signatures';

=head1 NAME

Conch::DB::ResultSet::DeviceReport

=head1 DESCRIPTION

Interface to queries involving device reports.

=head1 METHODS

=head2 with_report_status

Given a resultset indicating one or more report(s), adds a column to the result indicating
the cumulative status of all the validation state record(s) associated with it (that is, if all
pass, then return 'pass', otherwise consider if any were 'error' or 'fail').

Reports with no validation results are considered to be a 'pass'.

=cut

sub with_report_status ($self) {
    my $me = $self->current_source_alias;
    $self->search(
        undef,
        {
            '+select' => [ {
                    '' => \qq{case when $me.invalid_report is not null then 'error' else coalesce(min(validation_states.status),'pass') end},
                    -as => 'status',
                } ],
            join => 'validation_states',
            group_by => "$me.id",
        },
    );
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
