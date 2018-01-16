package Conch::Legacy::Control::Problem;

use strict;
use Log::Report;
use List::Compare;
use Mojo::JSON 'decode_json';

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

sub get_validation_criteria {
  my ($schema) = @_;

  my $criteria = {};

  my @rs = $schema->resultset('DeviceValidateCriteria')->search( {} )->all;
  foreach my $c (@rs) {
    $criteria->{ $c->id }{product_id} = $c->product_id || undef;
    $criteria->{ $c->id }{component}  = $c->component  || undef;
    $criteria->{ $c->id }{condition}  = $c->condition  || undef;
    $criteria->{ $c->id }{vendor}     = $c->vendor     || undef;
    $criteria->{ $c->id }{model}      = $c->model      || undef;
    $criteria->{ $c->id }{string}     = $c->string     || undef;
    $criteria->{ $c->id }{min}        = $c->min        || undef;
    $criteria->{ $c->id }{warn}       = $c->warn       || undef;
    $criteria->{ $c->id }{crit}       = $c->crit       || undef;
  }

  return $criteria;
}

sub workspace_devices {
  my ( $schema, $workspace_id ) = @_;
  return $schema->resultset('WorkspaceDevices')
    ->search( {}, { bind => [$workspace_id] } )->all;
}

sub unlocated_devices {
  my ( $schema, $user_id ) = @_;
  return $schema->resultset('UnlocatedUserRelayDevices')
    ->search( {}, { bind => [$user_id] } )->all;
}

# Gives a hash of Rack and Datacenter location details
sub device_rack_location {
  my ( $schema, $device_id ) = @_;

  my $location;
  my $device_location = device_location( $schema, $device_id );
  if ($device_location) {
    my $rack_info = get_rack( $schema, $device_location->rack_id );
    my $datacenter =
      get_datacenter_room( $schema, $rack_info->datacenter_room_id );
    my $target_hardware =
      get_target_hardware_product( $schema, $rack_info->id,
      $device_location->rack_unit );

    $location->{rack}{id}   = $device_location->rack_id;
    $location->{rack}{unit} = $device_location->rack_unit;
    $location->{rack}{name} = $rack_info->name;
    $location->{rack}{role} = $rack_info->role->name;

    $location->{target_hardware_product}{id}    = $target_hardware->id;
    $location->{target_hardware_product}{name}  = $target_hardware->name;
    $location->{target_hardware_product}{alias} = $target_hardware->alias;
    $location->{target_hardware_product}{vendor} =
      $target_hardware->vendor->name;

    $location->{datacenter}{id}          = $datacenter->id;
    $location->{datacenter}{name}        = $datacenter->az;
    $location->{datacenter}{vendor_name} = $datacenter->vendor_name;
  }

  return $location;
}

sub device_location {
  my ( $schema, $device_id ) = @_;
  my $device =
    $schema->resultset('DeviceLocation')->find( { device_id => $device_id } );
  return $device;
}

sub get_rack {
  my ( $schema, $rack_id ) = @_;
  my $rack = $schema->resultset('DatacenterRack')
    ->find( { id => $rack_id, deactivated => { '=', undef } } );
  return $rack;
}

sub get_datacenter_room {
  my ( $schema, $room_id ) = @_;
  my $room = $schema->resultset('DatacenterRoom')->find( { id => $room_id } );
  return $room;
}

# get the hardware product a device should be by rack location
sub get_target_hardware_product {
  my ( $schema, $rack_id, $rack_unit ) = @_;

  return $schema->resultset('HardwareProduct')->search(
    {
      'datacenter_rack_layouts.rack_id'  => $rack_id,
      'datacenter_rack_layouts.ru_start' => $rack_unit
    },
    { join => 'datacenter_rack_layouts' }
  )->single;
}

sub latest_device_report {
  my ( $schema, $device_id ) = @_;

  return $schema->resultset('LatestDeviceReport')
    ->search( {}, { bind => [$device_id] } )->first;
}

# Bundle up the validate logs for a given device report.
sub device_validation_report {
  my ( $schema, $report_id ) = @_;

  my @validate_report =
    $schema->resultset('DeviceValidate')->search( { report_id => $report_id } );

  my @reports;
  foreach my $r (@validate_report) {
    push @reports, decode_json( $r->validation );
  }

  return @reports;
}

1;
