package Conch::Legacy::Control::Device::Validation;

use strict;
use Log::Report;
use Data::UUID;
use Conch::Legacy::Control::Device::Configuration;
use Conch::Legacy::Control::Device::Environment;
use Conch::Legacy::Control::Device::Inventory;
use Conch::Legacy::Control::Device::Network;

use Exporter 'import';
our @EXPORT = qw( validate_device );

sub validate_device {
	my ( $schema, $device, $device_report, $report_id ) = @_;

	my @validations = $device_report->validations;
	try {
		foreach my $validation (@validations) {
			$validation->( $schema, $device, $report_id );
		}
	}
	accept => 'MISTAKE';    # Collect mistakes as failed validations

	# If no validators flagged anything, assume we're passing now. History will
	# be available in device_validate.
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
