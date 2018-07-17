=pod

=head1 NAME

Conch::Model::DeviceReport

=head1 METHODS

=cut
package Conch::Model::DeviceReport;
use Mojo::Base -base, -signatures;

use Conch::Pg;

=head2 latest_device_report

Look up the latest device report for a given device

=cut
sub latest_device_report ( $self, $device_id ) {
	my $ret = Conch::Pg->new->db->query(
		q{
      SELECT me.id, me.device_id, me.report, me.created
      FROM device_report me
      WHERE me.id IN (
        SELECT dr.id FROM device_report dr
        WHERE dr.device_id = ?
        ORDER BY dr.created DESC
        LIMIT 1
      )
    }, $device_id
	)->expand->hash;
	return $ret;
}

=head2 validation_results

Get the validation results for a given device report

=cut
sub validation_results ( $self, $report_id ) {
	Conch::Pg->new->db->select( 'device_validate', undef, { report_id => $report_id } )
		->expand->hashes->to_array;
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
