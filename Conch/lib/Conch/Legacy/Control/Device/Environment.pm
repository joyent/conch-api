package Conch::Legacy::Control::Device::Environment;

use strict;
use Log::Report;
use Mojo::JSON qw(decode_json encode_json);

use Exporter 'import';
our @EXPORT = qw( validate_cpu_temp validate_disk_temp );

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

	my $criteria = $schema->resultset('DeviceValidateCriteria')->search(
		{
			component => "CPU",
			condition => "temp"
		}
	)->single;

	$criteria or fault "no CPU device criteria defined";

	# XXX This should be aware of cpu_num, but for now, whatever.
	foreach my $cpu (qw/cpu0 cpu1/) {
		trace "$device_id: validating $cpu temp";
		my $cpu_msg;
		my $cpu_status;

		my $method = "${cpu}_temp";

		if ( $device_env->$method > $criteria->crit ) {
			$cpu_msg =
				  "$device_id: CRITICAL: $cpu: "
				. $device_env->$method . " (>"
				. $criteria->crit . ")";
			mistake $cpu_msg;
			$cpu_status = 0;
		}
		elsif ( $device_env->$method > $criteria->warn ) {
			$cpu_msg =
				  "$device_id: WARNING: $cpu: "
				. $device_env->$method . " (>"
				. $criteria->warn . ")";
			$cpu_status = 0;
		}
		else {
			$cpu_msg =
				  "$device_id: OK: $cpu: "
				. $device_env->$method . " (<"
				. $criteria->warn . ")";
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
						criteria_id    => $criteria->id,
						metric         => $device_env->$method,
						log            => $cpu_msg,
						status         => $cpu_status,
					}
				)
			}
		);
	}
}

sub validate_disk_temp {
	my ( $schema, $device, $report_id ) = @_;

	my $device_id = $device->id;

	trace("$device_id: report $report_id: Validating Disk temps");

	my $device = $schema->resultset('Device')->find($device_id);

	my $criteria_sas = $schema->resultset('DeviceValidateCriteria')->search(
		{
			component => "SAS_HDD",
			condition => "temp"
		}
	)->single;

	$criteria_sas or fault "no SAS_HDD device criteria defined";

	my $criteria_ssd = $schema->resultset('DeviceValidateCriteria')->search(
		{
			component => "SAS_SSD",
			condition => "temp"
		}
	)->single;

	$criteria_ssd or fault "no SAS_SSD device criteria defined";

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

		my $crit;
		my $warn;
		my $disk_msg;
		my $disk_status;
		my $criteria_id;

		if ( $disk->drive_type eq "SAS_HDD" ) {
			$crit        = $criteria_sas->crit;
			$warn        = $criteria_sas->warn;
			$criteria_id = $criteria_sas->id;
		}

		if ( $disk->drive_type eq "SAS_SSD" || $disk->drive_type eq "SATA_SSD" ) {
			$crit        = $criteria_ssd->crit;
			$warn        = $criteria_ssd->warn;
			$criteria_id = $criteria_ssd->id;
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
						criteria_id    => $criteria_id,
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

