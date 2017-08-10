package Conch::Control::Device;

use strict;
use List::Compare;
use Log::Report;
use Log::Report::DBIC::Profiler;
use Dancer2::Plugin::Passphrase;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( device_info device_location devices_for_user
                  device_ids_for_user device_inventory device_validation_report
                  update_device_location delete_device_location
                  get_validation_criteria get_active_devices
                  get_devices_by_health
                 );

sub get_validation_criteria {
  my ($schema) = @_;

  my $criteria = {};

  my @rs = $schema->resultset('DeviceValidateCriteria')->search({})->all;
  foreach my $c (@rs) {
    $criteria->{$c->id}{product_id} = $c->product_id || undef;
    $criteria->{$c->id}{component}  = $c->component || undef;
    $criteria->{$c->id}{condition}  = $c->condition || undef;
    $criteria->{$c->id}{vendor}     = $c->vendor || undef;
    $criteria->{$c->id}{model}      = $c->model || undef;
    $criteria->{$c->id}{string}     = $c->string || undef;
    $criteria->{$c->id}{min}        = $c->min || undef;
    $criteria->{$c->id}{warn}       = $c->warn || undef;
    $criteria->{$c->id}{crit}       = $c->crit || undef;
  }

  return $criteria;
}

sub devices_for_user  {
  my ($schema, $user_name) = @_;
  return $schema->resultset('UserDeviceAccess')->
      search({}, { bind => [$user_name] })->all;
}

sub device_ids_for_user {
  my ($schema, $user_name) = @_;

  my @user_device_ids;
  foreach my $device (devices_for_user($schema, $user_name)) {
    push @user_device_ids,$device->id;
  }
  return @user_device_ids;
}

sub get_active_devices {
  my ($schema, $user_name ) = @_;

  my @user_devices = device_ids_for_user($schema, $user_name);

  my @rs = $schema->resultset('Device')->search({
    last_seen => \' > NOW() - INTERVAL \'5 minutes\'',
  });

  my @active_devices;
  foreach my $a (@rs) {
    push @active_devices, $a->id;
  }

  my $lc = List::Compare->new(\@user_devices, \@active_devices);
  my @active_user_devices = $lc->get_intersection;

  return @active_user_devices;
}

# Return all devices that match health: $state
sub get_devices_by_health {
  my ($schema, $user_name, $state ) = @_;

  my @user_devices = device_ids_for_user($schema, $user_name);

  my @rs = $schema->resultset('Device')->search({
    health => "$state",
    deactivated => { '=', undef },
  });

  my @devices;
  foreach my $d (@rs) {
    push @devices, $d->id;
  }

  my $lc = List::Compare->new(\@user_devices, \@devices);
  my @return_devices = $lc->get_intersection;

  return @return_devices;
}

sub device_info {
  my ($schema, $device_id) = @_;
  my $device = $schema->resultset('Device')->find({id => $device_id});
  return $device;
}

sub device_location {
  my ($schema, $device_id) = @_;
  my $device = $schema->resultset('DeviceLocation')->find({device_id => $device_id});
  return $device;
}

sub device_inventory {
  my ($schema, $device_id) = @_;

  # Get the most recent entry in device_report.
  my $report = $schema->resultset('DeviceReport')->search(
    { device_id => $device_id },
    { order_by => { -desc => 'created' } }
  )->first;

  if ($report) {
    return ($report->id, Dancer2::Serializer::JSON::from_json($report->report));
  } else {
    return undef;
  }

}

# Bundle up the validate logs for a given device report.
sub device_validation_report {
  my ($schema, $report_id) = @_;

  my @validate_report = $schema->resultset('DeviceValidate')->search({ report_id => $report_id });

  my @reports;
  foreach my $r (@validate_report) {
    push @reports, Dancer2::Serializer::JSON::from_json($r->validation);
  }

  return @reports;
}

sub delete_device_location {
  my ($schema, $device_info) = @_;

  my $device    = $device_info->{device};
  my $rack_id   = $device_info->{rack};
  my $rack_unit = $device_info->{rack_unit};

  info "Going to remove $device from $rack_id:$rack_unit";

  my $rs = $schema->resultset('DeviceLocation')->find({
    device_id => $device_info->{device}
  });

  unless ($rs) {
    warning "Could not find $device in $rack_id:$rack_unit for removal";
    return undef
  }

  $rs->delete;

  if ($rs->in_storage) {
    warning "Failed to remove $device from $rack_id:$rack_unit";
    return undef;
  }

  info "Removed $device from $rack_id:$rack_unit";

  return 1;
}

sub update_device_location {
  my ($schema, $device_info) = @_;

  # If the device doesn't exist, create a stub entry for it.
  my $device_check = $schema->resultset('Device')->find({
    id => $device_info->{device}
  });

  unless ($device_check) {

    my $slot_info = $schema->resultset('DatacenterRackLayout')->search({
      rack_id   => $device_info->{rack},
      ru_start  => $device_info->{rack_unit}
    })->single;

    unless ($slot_info) {
      warning "Could not find a slot $device_info->{rack}:$device_info->{rack_unit} for device $device_info->{device}";
      return undef;
    }

    my $device_create = $schema->resultset('Device')->update_or_create({
      id     => $device_info->{device},
      health => "UNKNOWN",
      state  => "UNKNOWN",
      hardware_product => $slot_info->product_id,
    });

    unless ($device_create->in_storage) { return undef }
  }

  my $existing = $schema->resultset('DeviceLocation')->find({
    device_id => $device_info->{device}
  });

  # Log that we're moving a device if we are.
  if ($existing) {
    my $e_ru = $existing->rack_id.":".$existing->rack_unit;
    my $n_ru = $device_info->{rack}.":".$device_info->{rack_unit};

    if ( $e_ru ne $n_ru ) {
      warning "Moving $device_info->{device} from $e_ru to $n_ru";
    }
  }

  my $occupied = $schema->resultset('DeviceLocation')->search({
    rack_id   => $device_info->{rack},
    rack_unit => $device_info->{rack_unit}
  })->single;

  # XXX I couldn't figure out how to defref this properly!
  # XXX It made me nuts :( -- bdha
  # Refuse to move a device to a slot occupied by another device.
  if ($occupied) {
    my $occupied_device = $occupied->device_id;

    unless ( $occupied_device == $device_info->{device} ) {
      # XXX This needs a real error message.
      warning "Cannot move $device_info->{device} to $device_info->{rack}:$device_info->{rack_unit}, occupied by $occupied_device";
      return undef;
    }
  }

  info "Updating location for $device_info->{device} to $device_info->{rack}:$device_info->{rack_unit}";
  my $result = $schema->resultset('DeviceLocation')->update_or_create({
    device_id => $device_info->{device},
    rack_id   => $device_info->{rack},
    rack_unit => $device_info->{rack_unit}
  });
}

1;
