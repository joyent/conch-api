=pod

=head1 NAME

Conch::Legacy::Control::Device::Environment - B<LEGACY MODULE>

=head1 METHODS

=cut
package Conch::Legacy::Control::Device::Environment;

use strict;
use Log::Report;
use Mojo::JSON qw(decode_json encode_json);

use Exporter 'import';
our @EXPORT = qw( validate_cpu_temp validate_disk_temp );

=head2 validate_cpu_temp

Valdidate device CPU temperatures

=cut
sub validate_cpu_temp {
	my ( $schema, $device, $report_id ) = @_;

	$device or fault "device undefined";

	my $device_id = $device->id;
	trace "$device_id: report $report_id: validating cpu temps";

	my $device_env = $schema->resultset('DeviceEnvironment')->search(
		{
			device_id => $device_id,
		},
		{
			order_by => 'updated'
		}
	)->single;


	# XXX This should be aware of cpu_num, but for now, whatever.
	foreach my $cpu (qw/cpu0 cpu1/) {
		trace "$device_id: validating $cpu temp";
		my $cpu_msg;
		my $cpu_status;

		my $method = "${cpu}_temp";

		if ( $device_env->$method > 70 ) {
			$cpu_msg =
				  "$device_id: CRITICAL: $cpu: "
				. $device_env->$method . " (>"
				. 70 . ")";
			mistake $cpu_msg;
			$cpu_status = 0;
		}
		elsif ( $device_env->$method > 60 ) {
			$cpu_msg =
				  "$device_id: WARNING: $cpu: "
				. $device_env->$method . " (>"
				. 60 . ")";
			$cpu_status = 0;
		}
		else {
			$cpu_msg =
				  "$device_id: OK: $cpu: "
				. $device_env->$method . " (<"
				. 60 . ")";
			$cpu_status = 1;
		}

		info($cpu_msg);

		my $device_validate = $schema->resultset('DeviceValidate')->create(
			{
				device_id  => $device_id,
				report_id  => $report_id,
				validation => encode_json(
					{
						component_type => "CPU",
						component_name => $cpu,
						metric         => $device_env->$method,
						log            => $cpu_msg,
						status         => $cpu_status,
					}
				)
			}
		);
	}
}

=head2 validate_disk_temp

Valdidate device disk temperatures

=cut
sub validate_disk_temp {
	my ( $schema, $device, $report_id ) = @_;

	my $device_id = $device->id;

	trace("$device_id: report $report_id: Validating Disk temps");

	my $device = $schema->resultset('Device')->find($device_id);


	my $disks = $schema->resultset('DeviceDisk')->search(
		{
			device_id   => $device_id,
			deactivated => { '=', undef },
			transport   => { '!=', "usb" }    # No temps for USB devices.
		}
	);

	while ( my $disk = $disks->next ) {
		trace("$device_id: report $report_id: "
				. $disk->id . ": "
				. $disk->serial_number
				. ": validating temps" );

		my $crit = 51;
		my $warn = 41;
		my $disk_msg;
		my $disk_status;

		if ( $disk->drive_type eq "SAS_HDD" ) {
			$crit        = 60;
		}

		if ( $disk->temp > $crit ) {
			$disk_status = 0;
			$disk_msg =
				  "CRITICAL: "
				. $disk->serial_number . ": "
				. $disk->temp . " (>"
				. $crit . ")";
			mistake $disk_msg;
		}
		elsif ( $disk->temp > $warn ) {
			$disk_msg =
				  "WARNING; "
				. $disk->serial_number . ": "
				. $disk->temp . " (>"
				. $warn . ")";
			$disk_status = 1;
		}
		else {
			$disk_msg = "OK: "
				. $disk->serial_number . ": "
				. $disk->temp . " (<"
				. $warn . ")";
			$disk_status = 1;
		}

		trace "$device_id: report $report_id: "
			. $disk->id . ": "
			. $disk->serial_number . ": "
			. $disk_msg;

		my $device_validate = $schema->resultset('DeviceValidate')->create(
			{
				device_id  => $device_id,
				report_id  => $report_id,
				validation => encode_json(
					{
						component_type => $disk->drive_type,
						component_name => $disk->serial_number,
						component_id   => $disk->id,
						metric         => $disk->temp,
						log            => $disk_msg,
						status         => $disk_status,
					}
				)
			}
		);
	}
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

