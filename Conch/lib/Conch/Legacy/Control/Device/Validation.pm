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

use Mojo::Exception;

use Exporter 'import';
our @EXPORT = qw( validate_device );

=head2 validate_device

Run device validations with a device report.

=cut

sub validate_device {
	my ( $schema, $device, $device_report, $report_id ) = @_;

	my @validations = $device_report->validations;
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
		Mojo::Exception->throw(
			$device->id . ": Marking FAIL because exception occurred: $message" );
	}

	my $validation_errors = $@ if $@;
	if ( $validation_errors && $validation_errors->exceptions > 0 ) {
		my @errors = $validation_errors->exceptions;
		map { trace $_; } @errors;
		warning( $device->id . ": Marking FAIL" );
		$device->update( { health => "FAIL" } );
		return { health => "FAIL", errors => \@errors };
	}
	else {
		info( $device->id . ": Marking PASS" );
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
