package Conch::Control::Device::Validation;

use strict;
use Log::Report mode => 'DEBUG';
use Data::UUID;
use Conch::Control::Device::Configuration;
use Conch::Control::Device::Environment;
use Conch::Control::Device::Inventory;
use Conch::Control::Device::Network;

use Exporter 'import';
our @EXPORT = qw( validate_device );

sub validate_device {
  my ($schema, $device, $report_id) = @_;
  my $report_id  = Data::UUID->new->create_str();

  # all of the validation functions to run
  # validation function should have the following signature:
  # `my ($schema, $device, $report_id) = @_;`
  my @validations = (
    \&validate_cpu_temp,
    \&validate_disk_temp,
    \&validate_product,
    \&validate_system,
    \&validate_disks,
    \&validate_links,
    # Wiremaps don't exist yet
    #\&validate_wiremap,

  );

  try {
    foreach my $validation (@validations) {
      $validation->($schema, $device, $report_id);
    }
  } accept => 'MISTAKE'; # Collect mistakes as failed validations

  # If no validators flagged anything, assume we're passing now. History will
  # be available in device_validate.
  if ($@->exceptions > 0) {
      map { trace $_; } $@->exceptions;
      trace($device->id . ": Marking FAIL");
      $device->update({ health => "FAIL" });
  } else {
      trace($device->id . ": Marking PASS");
      $device->update({ health => "PASS" });
  }
}

1;
