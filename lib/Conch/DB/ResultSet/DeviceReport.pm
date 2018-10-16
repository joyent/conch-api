package Conch::DB::ResultSet::DeviceReport;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use Mojo::JSON 'from_json';
use Conch::UUID 'is_uuid';

=head1 NAME

Conch::DB::ResultSet::DeviceReport

=head1 DESCRIPTION

Interface to queries involving device reports.

=head1 METHODS

=head2 matches_jsonb

Search for reports that match the the passed-in json blob.

Current fields ignored in the comparisons:

    * report_id
    * fans
    * psus
    * lldp_neighbors
    * temp
    * disks->*->temp

=cut

sub matches_jsonb {
    my ($self, $jsonb) = @_;

    my @disks = keys from_json($jsonb)->{disks}->%*;
    my $ignore_fields = join(' - ', map { "'$_'" } qw(report_id fans psus lldp neighbors temp))
        . join(' ', map { "#- '{disks,$_,temp}'" } @disks);

    my $me = $self->current_source_alias;
    $self->search(\[ "($me.report - $ignore_fields) = (?::jsonb - $ignore_fields)", $jsonb ]);
}

=head2 matches_report_id

Search for reports that match the json blob from the report referenced by the passed-in id.

Current fields ignored in the comparisons:

    * report_id
    * fans
    * psus
    * lldp_neighbors
    * temp
    * disks->*->temp

=cut

sub matches_report_id {
    my ($self, $report_id) = @_;

    Carp::croak('did not supply report_id') if not $report_id or not is_uuid($report_id);

    my $compare_report_rs = $self->result_source->resultset
        ->search({ 'subquery.id' => $report_id }, { alias => 'subquery' });

    # ideally I'd like to do all this server-side, but I'm not sure how to subtract
    # all these from 'device_report.report' once I've assembled:
    # select '{disks,' || disk || ',temp}'
    # from (select jsonb_object_keys(report->'disks') as disk from device_report where id = ?

    my @disks = $compare_report_rs
        ->search(undef, { select => \q{jsonb_object_keys(subquery.report->'disks')}, as => 'disk' })
        ->get_column('disk')
        ->all;

    my $ignore_fields = join(' - ', map { "'$_'" } qw(report_id fans psus lldp neighbors temp))
        . join(' ', map { "#- '{disks,$_,temp}'" } @disks);

    my $me = $self->current_source_alias;

    my $jsonb_rs = $compare_report_rs
        ->search(undef, { select => \"report - $ignore_fields" });

    $self->search({ "($me.report - $ignore_fields)" => { '=' => $jsonb_rs->as_query } });
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
