package Conch::Control::Device::Validation;

use strict;
use Log::Report;
use Data::UUID;
use Conch::Control::Device::Configuration;
use Conch::Control::Device::Environment;
use Conch::Control::Device::Inventory;
use Conch::Control::Device::Network;

use Exporter 'import';
our @EXPORT = qw( validate_device );

sub validate_device {
  my ($schema, $device, $device_report, $report_id) = @_;

  my @validations = $device_report->validations;
  try {
    foreach my $validation (@validations) {
      $validation->($schema, $device, $report_id);
    }
  } accept => 'MISTAKE'; # Collect mistakes as failed validations

  # If no validators flagged anything, assume we're passing now. History will
  # be available in device_validate.
  if ($@->exceptions > 0) {
      map { trace $_; } $@->exceptions;
      warning($device->id . ": Marking FAIL");
      $device->update({ health => "FAIL" });
      return { health => "FAIL" };
  } else {
      info($device->id . ": Marking PASS");
      $device->update({ health => "PASS" });
      return { health => "PASS" };
  }
}

1;
