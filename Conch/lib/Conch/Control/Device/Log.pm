package Conch::Control::Device::Log;

use v5.10;
use strict;
use Log::Report;
use Log::Report::DBIC::Profiler;
use Dancer2::Plugin::Passphrase;

use Conch::Data::DeviceLog;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw(parse_device_log record_device_log get_device_logs );

# Parse a DeviceLog object from a HashRef and report all validation errors
sub parse_device_log {
  my $dr;

  eval { $dr = Conch::Data::DeviceLog->new(shift); };
  if ($@) {
    my $errs = join( "; ", map { $_->message } $@->errors );
    error "Error validating device log $errs.";
  }
  else {
    return $dr;
  }
}

sub record_device_log {
  my ( $schema, $device, $device_log ) = @_;

  $device->device_logs->create(
    {
      device_id      => $device->id,
      component_type => $device_log->component_type,
      component_id   => $device_log->component_id,
      log            => $device_log->msg
    }
  );
}

sub get_device_logs {
  my ( $schema, $device, $component_type, $component_id, $limit ) = @_;

  my $search_filter = {};
  $search_filter->{component_type} = $component_type if $component_type;
  $search_filter->{component_id}   = $component_id   if $component_id;

  my $search_attrs = { order_by => { -desc => 'created' } };
  $search_attrs->{rows} = $limit if $limit;

  my @device_logs = try {
    $device->device_logs->search( $search_filter, $search_attrs )->all
  };
  $@->reportFatal;

  return map format_log($_), @device_logs;
}

sub format_log {
  my $device_log = shift;
  return {
    component_type => $device_log->component_type,
    component_id   => $device_log->component_id,
    msg            => $device_log->log,
    created        => "" . $device_log->created
  };
}

1;
