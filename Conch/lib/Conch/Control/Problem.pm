package Conch::Control::Problem;

use strict;
use Log::Report;
use List::Compare;
use Conch::Control::User;
use Conch::Control::Device;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( get_problems );

# The report / validation format is not normalized yet, so this is going to be
# a giant mess. Sorry. -- bdha
sub get_problems {
  my ( $schema, $user_id, $workspace_id ) = @_;

  my $criteria = get_validation_criteria($schema);

  my @failing_user_devices;
  my @unreported_user_devices;
  my @unlocated_user_devices;
  foreach my $d ( workspace_devices( $schema, $workspace_id ) ) {
    if ( $d->health eq 'FAIL' ) {
      push @failing_user_devices, $d;
    }
    if ( $d->health eq 'UNKNOWN' ) {
      push @unreported_user_devices, $d;
    }
  }

  foreach my $d ( unlocated_devices( $schema, $user_id ) ) {
    push @unlocated_user_devices, $d;
  }

  my $failing_problems = {};
  foreach my $device (@failing_user_devices) {
    my $device_id = $device->id;

    $failing_problems->{$device_id}{health} = $device->health;
    $failing_problems->{$device_id}{location} =
      device_rack_location( $schema, $device_id );

    my $report = latest_device_report( $schema, $device_id );
    $failing_problems->{$device_id}{report_id} = $report->id;
    my @failures = validation_failures( $schema, $criteria, $report->id );
    $failing_problems->{$device_id}{problems} = \@failures;
  }

  my $unreported_problems = {};
  foreach my $device (@unreported_user_devices) {
    my $device_id = $device->id;

    $unreported_problems->{$device_id}{health} = $device->health;
    $unreported_problems->{$device_id}{location} =
      device_rack_location( $schema, $device_id );
  }

  my $unlocated_problems = {};
  foreach my $device (@unlocated_user_devices) {
    my $device_id = $device->id;

    $unlocated_problems->{$device_id}{health} = $device->health;
    my $report = latest_device_report( $schema, $device_id );
    $unlocated_problems->{$device_id}{report_id} = $report->id;
    my @failures = validation_failures( $schema, $criteria, $report->id );
    $unlocated_problems->{$device_id}{problems} = \@failures;
  }

  return {
    failing    => $failing_problems,
    unreported => $unreported_problems,
    unlocated  => $unlocated_problems
  };
}

sub validation_failures {
  my ( $schema, $criteria, $report_id ) = @_;
  my @failures;

  my @validation_report = device_validation_report( $schema, $report_id );
  foreach my $v (@validation_report) {
    my $fail = {};
    if ( $v->{status} eq 0 ) {
      $fail->{criteria}{id} = $v->{criteria_id} || undef;
      $fail->{criteria}{component} =
        $criteria->{ $v->{criteria_id} }{component} || undef;
      $fail->{criteria}{condition} =
        $criteria->{ $v->{criteria_id} }{condition} || undef;
      $fail->{criteria}{min}  = $criteria->{ $v->{criteria_id} }{min}  || undef;
      $fail->{criteria}{warn} = $criteria->{ $v->{criteria_id} }{warn} || undef;
      $fail->{criteria}{crit} = $criteria->{ $v->{criteria_id} }{crit} || undef;

      $fail->{component_id}   = $v->{component_id}   || undef;
      $fail->{component_name} = $v->{component_name} || undef;
      $fail->{component_type} = $v->{component_type} || undef;
      $fail->{log}            = $v->{log}            || undef;
      $fail->{metric}         = $v->{metric}         || undef;

      push @failures, $fail;
    }
  }

  return @failures;
}

1;
