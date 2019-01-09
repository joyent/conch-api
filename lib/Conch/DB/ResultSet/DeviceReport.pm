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

=head2 matches_jsonb

Search for reports that match the the passed-in json blob.

Current fields ignored in the comparisons:

    * report_id

=cut

sub matches_jsonb ($self, $jsonb) {
    my $ignore_fields = join(' - ', map { "'$_'" } qw(report_id));

    my $me = $self->current_source_alias;
    $self->search(\[ "($me.report - $ignore_fields) = (?::jsonb - $ignore_fields)", $jsonb ]);
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
