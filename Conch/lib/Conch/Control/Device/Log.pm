package Conch::Control::Device::Log;

use v5.10;
use strict;
use List::Compare;
use Log::Report;
use Log::Report::DBIC::Profiler;
use Dancer2::Plugin::Passphrase;

use Conch::Data::DeviceLog;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw(parse_device_log record_device_log get_device_logs get_device_component_logs);

# Parse a DeviceLog object from a HashRef and report all validation errors
sub parse_device_log {
  my $dr;

  eval {
    $dr = Conch::Data::DeviceLog->new(shift);
  };
  if ($@) {
    my $errs = join("; ", map { $_->message } $@->errors);
    error "Error validating device report: $errs.";
  }
  else {
    return $dr;
  }
}

sub record_device_log {
  my ($schema, $device, $device_log) = @_;

  $device->device_logs->create({
      device_id      => $device->id,
      component_type => $device_log->component_type,
      component_id   => $device_log->component_id,
      log            => $device_log->msg
  });
}

sub get_device_logs {
  my ($schema, $device) = @_;
  my @device_logs =  $device->device_logs->search({}, { order_by => { -asc => 'created' }})->all;

  return map {
    {
      component_type => $_->component_type,
      component_id => $_->component_id,
      msg => $_->log,
      created => "".$_->created
    }
  } @device_logs;
}

sub get_device_component_logs {
  my ($schema, $device, $component_type) = @_;
  my @device_logs =  $device->device_logs->search(
    { component_type => $component_type }, { order_by => { -asc => 'created' }}
  )->all;

  return map {
    {
      component_type => $_->component_type,
      component_id => $_->component_id,
      msg => $_->log,
      created => "".$_->created
    }
  } @device_logs;
}

1;
