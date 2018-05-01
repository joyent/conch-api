=pod

=head1 NAME

Conch::Legacy::Control::Device::Validation - B<LEGACY MODULE>

=head1 METHODS

=cut

package Conch::Legacy::Control::Device::Validation;

use strict;
use Log::Report;
use Data::UUID;
use Conch::Legacy::Control::Device::Configuration;
use Conch::Legacy::Control::Device::Environment;
use Conch::Legacy::Control::Device::Inventory;
use Conch::Legacy::Control::Device::Network;

use Mojo::JSON qw(encode_json);

use Exporter 'import';
our @EXPORT = qw( validate_device );

=head2 validate_device

Run device validations with a device report.

=cut

sub validate_device {
	my ( $schema, $device, $device_report, $report_id, $logger ) = @_;

	my @validations;
	if ( $device_report->{device_type}
		&& $device_report->{device_type} eq 'switch' )
	{
		# validations for switches
		@validations =
			( \&validate_system, \&validate_cpu_temp, \&validate_bios_firmware );
	}
	else {
		# validations for servers
		@validations = (
			\&validate_cpu_temp,
			\&validate_product,
			\&validate_system,
			\&validate_nics_num,
			$device_report->{disks}      ? \&validate_disk_temp : (),
			$device_report->{disks}      ? \&validate_disks     : (),
			$device_report->{interfaces} ? \&validate_links     : (),
			$device_report->{interfaces} ? \&validate_wiremap   : (),
		);
	}
	try {
		foreach my $validation (@validations) {
			$validation->( $schema, $device, $report_id );
		}
	}
	accept => 'MISTAKE';    # Collect mistakes as failed validations

	# Catch unhandled errors
	if ( $@->died ) {
		$device->update( { health => "FAIL" } );

		my $died    = $@->died;
		my $message = "$died";
		if ( $died->can('report_opts') ) {
			my $report_loc = $died->report_opts->{location};
			my $src_file   = $report_loc->[1];
			my $src_line   = $report_loc->[2];
			$message .= " at $src_file line $src_line";
		}

		$schema->resultset('DeviceValidate')->create(
			{
				device_id  => $device->id,
				report_id  => $report_id,
				validation => encode_json(
					{
						component_type => '000',
						log => "Exception occurred during device validation: $message."
							. ' Administrators should check logs for more information.',
						status => 0,
					}
				)
			}
		);

		$logger->error(
			$device->id . ": Marking FAIL because exception occurred: $message" );
		return { health => "FAIL", errors => [$message] };
	}
	elsif ( $@->exceptions > 0 ) {
		my @errors = $@->exceptions;
		$logger->warn( $device->id . ": Marking FAIL" );
		$device->update( { health => "FAIL" } );
		return { health => "FAIL", errors => \@errors };
	}
	else {
		$logger->info( $device->id . ": Marking PASS" );
		$device->update( { health => "PASS" } );
		return { health => "PASS" };
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
