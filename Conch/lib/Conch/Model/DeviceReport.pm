package Conch::Model::DeviceReport;
use Mojo::Base -base, -signatures;

has 'pg';
has 'log';

sub latest_device_report ( $self, $device_id ) {
	my $ret = $self->pg->db->query(
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

sub validation_results ( $self, $report_id ) {
	$self->pg->db->select( 'device_validate', undef, { report_id => $report_id } )
		->expand->hashes->to_array;
}

1;


__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

