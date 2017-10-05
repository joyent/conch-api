package Conch::Control::Device;

use strict;
use List::Compare;
use Log::Any '$log';
use Dancer2::Plugin::Passphrase;

use Conch::Control::Rack;
use Conch::Control::Datacenter;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( get_device device_location all_user_devices devices_for_user
  lookup_device_for_user device_rack_location
  device_ids_for_user latest_device_report device_validation_report
  update_device_location delete_device_location
  get_validation_criteria get_active_devices
  get_devices_by_health unlocated_devices device_response
  mark_device_validated
);

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

sub devices_for_user {
  my ( $schema, $user_name ) = @_;
  return $schema->resultset('UserDeviceAccess')
    ->search( {}, { bind => [$user_name] } )->all;
}

sub lookup_device_for_user {
  my ( $schema, $device_id, $user_name ) = @_;
  my $device = $schema->resultset('UserDeviceAccess')
    ->search( { id => $device_id }, { bind => [$user_name] } )->single;

  # Look for an unlocated device if no located device found
  $device = $device
    || $schema->resultset('UnlocatedUserRelayDevices')
    ->search( { id => $device_id }, { bind => [$user_name] } )->single;
  return $device;
}

sub unlocated_devices {
  my ( $schema, $user_name ) = @_;
  return $schema->resultset('UnlocatedUserRelayDevices')
    ->search( {}, { bind => [$user_name] } )->all;
}

# Includes located and unlocated devices
sub all_user_devices {
  my ( $schema, $user_name ) = @_;
  return (
    devices_for_user( $schema, $user_name ),
    unlocated_devices( $schema, $user_name )
  );
}

sub device_ids_for_user {
  my ( $schema, $user_name ) = @_;

  my @user_device_ids;

  foreach my $device ( all_user_devices( $schema, $user_name ) ) {
    push @user_device_ids, $device->id;
  }

  return @user_device_ids;
}

sub get_active_devices {
  my ( $schema, $user_name ) = @_;

  my @user_devices = device_ids_for_user( $schema, $user_name );

  my @rs = $schema->resultset('Device')->search(
    {
      last_seen => \' > NOW() - INTERVAL \'5 minutes\'',
    }
  );

  my @active_devices;
  foreach my $a (@rs) {
    push @active_devices, $a->id;
  }

  my $lc = List::Compare->new( \@user_devices, \@active_devices );
  my @active_user_devices = $lc->get_intersection;

  return @active_user_devices;
}

# Return all devices that match health: $state
sub get_devices_by_health {
  my ( $schema, $user_name, $state ) = @_;

  my @user_devices = device_ids_for_user( $schema, $user_name );

  my @rs = $schema->resultset('Device')->search(
    {
      health      => "$state",
      deactivated => { '=', undef },
    }
  );

  my @devices;
  foreach my $d (@rs) {
    push @devices, $d->id;
  }

  my $lc = List::Compare->new( \@user_devices, \@devices );
  my @return_devices = $lc->get_intersection;

  return @return_devices;
}

sub get_device {
  my ( $schema, $device_id ) = @_;
  my $device = $schema->resultset('Device')->find( { id => $device_id } );
  return $device;
}

sub device_location {
  my ( $schema, $device_id ) = @_;
  my $device =
    $schema->resultset('DeviceLocation')->find( { device_id => $device_id } );
  return $device;
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

    $location->{rack}{id}   = $device_location->rack_id;
    $location->{rack}{unit} = $device_location->rack_unit;
    $location->{rack}{name} = $rack_info->name;
    $location->{rack}{role} = $rack_info->role->name;

    $location->{datacenter}{id}   = $datacenter->id;
    $location->{datacenter}{name} = $datacenter->az;
  }

  return $location;
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
    push @reports, Dancer2::Serializer::JSON::from_json( $r->validation );
  }

  return @reports;
}

sub delete_device_location {
  my ( $schema, $device_info ) = @_;

  my $device    = $device_info->{device};
  my $rack_id   = $device_info->{rack};
  my $rack_unit = $device_info->{rack_unit};

  $log->info("Going to remove $device from $rack_id:$rack_unit");

  my $rs = $schema->resultset('DeviceLocation')->find(
    {
      device_id => $device_info->{device}
    }
  );

  unless ($rs) {
    $log->warning("Could not find $device in $rack_id:$rack_unit for removal");
    return undef;
  }

  $rs->delete;

  if ( $rs->in_storage ) {
    $log->warning("Failed to remove $device from $rack_id:$rack_unit");
    return undef;
  }

  $log->info("Removed $device from $rack_id:$rack_unit");

  return 1;
}

sub update_device_location {
  my ( $schema, $device_info, $user_name ) = @_;

  my $slot_info = $schema->resultset('DatacenterRackLayout')->search(
    {
      rack_id  => $device_info->{rack},
      ru_start => $device_info->{rack_unit}
    }
  )->single;

  unless ($slot_info) {
    return (
      undef,
      $log->warningf(
        "Could not find a slot %s : %s for assigning to device",
        $device_info->{rack}, $device_info->{rack_unit},
        $device_info->{device}
      )
    );
  }

  my $occupied = $schema->resultset('DeviceLocation')->search(
    {
      rack_id   => $device_info->{rack},
      rack_unit => $device_info->{rack_unit}
    }
  )->single;

  if ($occupied) {
    my $occupied_device = $occupied->device_id;

    # Location is currently occupied
    unless ( $occupied_device eq $device_info->{device} ) {
      return (
        undef,
        $log->warningf(
          "Cannot move device %s to rack %s, slot %s, occupied by device %s",
          $device_info->{device},    $device_info->{rack},
          $device_info->{rack_unit}, $occupied_device
        )
      );
    }

    # Nothing to do; is already assigned to this location
    $log->infof(
      "Device %s already occupies rack %s, slot %s",
      $device_info->{device},
      $device_info->{rack}, $device_info->{rack_unit},
    );
    return ( $occupied, undef );
  }

  my $device = get_device( $schema, $device_info->{device} );

  # Create a device if it doesn't exist
  unless ($device) {
    $device = $schema->resultset('Device')->create(
      {
        id               => $device_info->{device},
        health           => "UNKNOWN",
        state            => "UNKNOWN",
        hardware_product => $slot_info->product_id,
      }
    );
    Log::Any->get_logger( category => 'user.action.device.create' )
      ->infof( "User '%s' created device %s to assign to location",
      $user_name, $device->id );
  }

  my $existing = $schema->resultset('DeviceLocation')->find(
    {
      device_id => $device_info->{device}
    }
  );

  my $result = $schema->resultset('DeviceLocation')->update_or_create(
    {
      device_id => $device_info->{device},
      rack_id   => $device_info->{rack},
      rack_unit => $device_info->{rack_unit}
    }
  );
  Log::Any->get_logger( category => 'user.action.device.update_location' )
    ->infof(
    "User '%s' assigned device %s location to rack %s, slot %s",
    $user_name,           $device_info->{device},
    $device_info->{rack}, $device_info->{rack_unit}
    );

  return ( $result, undef );
}

sub mark_device_validated {

  # $device may be a virtual view
  my ( $schema, $device ) = @_;
  $schema->resultset('Device')->find( { id => $device->id } )
    ->update( { validated => \'NOW()', updated => \'NOW()' } );
  return 1;
}

1;
