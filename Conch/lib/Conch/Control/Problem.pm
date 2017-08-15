package Conch::Control::Problem;

use strict;
use Log::Report;
use List::Compare;
use Dancer2::Plugin::Passphrase;
use Conch::Control::User;
use Conch::Control::Datacenter;
use Conch::Control::Device;
use Conch::Control::Rack;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( get_problems );

# The report / validation format is not normalized yet, so this is going to be
# a giant mess. Sorry. -- bdha
sub get_problems {
  my ($schema, $user_name) = @_;

  my $problems   = {};
  my $rack_roles = rack_roles($schema);
  my $criteria   = get_validation_criteria($schema);

  my @failing_user_devices;
  foreach my $d (devices_for_user($schema, $user_name)) {
    if ($d->health eq 'FAIL' || $d->health eq 'UNKNOWN') {
      push @failing_user_devices, $d;
    }
  }

  foreach my $d (unlocated_devices($schema, $user_name)) {
      push @failing_user_devices, $d;
  }

  foreach my $device (@failing_user_devices) {
    my $device_id       = $device->id;
    my $device_location = device_location($schema, $device_id);

    $problems->{$device_id}{health} = $device->health;
    my @problems;

    if ($device_location) {
      my $rack_info       = get_rack($schema, $device_location->rack_id);
      my $datacenter      = get_datacenter_room($schema, $rack_info->datacenter_room_id);

      $problems->{$device_id}{rack}{id}   = $device_location->rack_id || undef;
      $problems->{$device_id}{rack}{unit} = $device_location->rack_unit || undef;
      $problems->{$device_id}{rack}{name} = $rack_info->name || undef;
      $problems->{$device_id}{rack}{role} = $rack_info->role->name || undef;

      $problems->{$device_id}{datacenter}{id}   = $datacenter->id;
        $problems->{$device_id}{datacenter}{name} = $datacenter->az;
    }
    else {
      $problems->{$device_id}{rack} = undef;
      $problems->{$device_id}{datacenter} = undef;
      my $fail = {};
      $fail->{log} = "Device not assigned to datacenter rack" ;
      $fail->{component_type} = "Location" ;
      $fail->{component_name} = "Location" ;
      $fail->{criteria}{condition} = "Location" ;
      push @problems, $fail;
    }

    my $report = newest_report($schema, $device_id);
    if ($report) {
      $problems->{$device_id}{report_id}  = $report->id;
      my @validation_report = device_validation_report($schema, $report->id);
      foreach my $v (@validation_report) {
        my $fail = {};
        if ($v->{status} eq 0) {
          $fail->{criteria}{id}           = $v->{criteria_id} || undef;
          $fail->{criteria}{component}    = $criteria->{ $v->{criteria_id} }{component} || undef;
          $fail->{criteria}{condition}    = $criteria->{ $v->{criteria_id} }{condition} || undef;
          $fail->{criteria}{min}          = $criteria->{ $v->{criteria_id} }{min} || undef;
          $fail->{criteria}{warn}         = $criteria->{ $v->{criteria_id} }{warn} || undef;
          $fail->{criteria}{crit}         = $criteria->{ $v->{criteria_id} }{crit} || undef;

          $fail->{component_id}   = $v->{component_id} || undef;
          $fail->{component_name} = $v->{component_name} || undef;
          $fail->{component_type} = $v->{component_type} || undef;
          $fail->{log}            = $v->{log} || undef;
          $fail->{metric}         = $v->{metric} || undef;
          push @problems,$fail;
        }
      }
    }
    else {
      $problems->{$device_id}{report_id} = undef;
      my $fail = {};
      if ($problems->{$device_id}{rack}) {
        $fail->{log} = "No report from Rack $problems->{$device_id}{rack}{name}, Slot $problems->{$device_id}{rack}{unit}";
      }
      else {
        $fail->{log} = "No reports received from device";
      }
      $fail->{component_type} = "Report" ;
      $fail->{component_name} = "Report" ;
      $fail->{criteria}{condition} = "Report" ;
      push @problems, $fail;
    }
    $problems->{$device_id}{problems} = \@problems;
  }

  return $problems;
}

sub newest_report {
  my ($schema, $device) = @_;

  # Get the most recent entry in device_report.
  my $report = $schema->resultset('DeviceReport')->search(
    { device_id => $device },
    { order_by => { -desc => 'created' },
      columns => qw/id created/ }
  )->first;

  return $report;
}

1;
