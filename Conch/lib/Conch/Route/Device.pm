package Conch::Route::Device;

use strict;

use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport;
use Dancer2::Plugin::REST;
use Hash::MultiValue;
use Data::Validate::UUID 'is_uuid';
use Scalar::Util 'looks_like_number';

use Conch::Control::Device::Profile;
use Conch::Control::Device::Validation;
use Conch::Control::Device::Log;
use Conch::Control::Device;
use Conch::Control::DeviceReport;
use Conch::Control::Relay;

use Data::Printer;

set serializer => 'JSON';

# Return all devices an integrator user has access to
# Admins currently don't have access to endpoint and they get a 401.
# TODO: If we want to add admin access, what should this endpoint return? All
# devices across all DCs?
get '/device' => needs integrator => sub {
  my $user_name = session->read('integrator');
  my @devices;
  if (param 'full') {
    for my $d (all_user_devices(schema, $user_name)) {
      my %data = $d->get_columns;
      push @devices, \%data;
    }
  }
  else {
    @devices = device_ids_for_user(schema, $user_name);
  }
  return status_200(\@devices || []);
};

get '/device/status' => needs integrator => sub {
};


get '/device/active' => needs integrator => sub {
  my $user_name = session->read('integrator');
  my @devices = get_active_devices(schema, $user_name);
  status_200(\@devices);
};

get '/device/health/:state' => needs integrator => sub {
  my $user_name = session->read('integrator');
  my $state = param 'state';

  if ($state !~ /PASS|FAIL/) {
    return status_500({error => "/device/health/:state must be PASS or FAIL"});
  }

  my @devices = get_devices_by_health(schema, $user_name, $state);
  status_200(\@devices);
};

get '/device/:serial' => needs integrator => sub {
  my $user_name = session->read('integrator');
  my $serial    = param 'serial';

  my $device = lookup_device_for_user(schema, $serial, $user_name);

  unless ($device) {
    warning "$user_name not allowed to view device $serial or $serial does not exist";
    return status_401('unauthorized');
  }

  my @validations = ();
  my $report = {};
  my $device_report = latest_device_report(schema, $serial);
  if ($device_report) {
    @validations = device_validation_report(schema, $device_report->id);
    $report = from_json($device_report->report);
    delete $report->{'__CLASS__'};
  }

  my $response = {$device->get_columns};
  $response->{latest_report} = $report;
  $response->{validations} = \@validations;

  status_200($response);
};

post '/device/:serial' => needs integrator => sub {
  my $user_name = session->read('integrator');
  my $serial    = param 'serial';

  my ($device, $report_id, $device_report);

  # NOTE This stops reports being ingested until the device is slotted into a rack.
  #      This may not be desireable. Once the device is entered into device_location
  #      via /rack/:rackid, reports can be consumed. This checks does stop, in theory,
  #      people from submitting reports for hosts they don't control.

  # XXX Move this to Conch::Control::check_device_access(schema, $user_name, $serial);
  # Verify the requested device is accessible to this user.
  #my @user_devices;
  #@user_devices = device_ids_for_user(schema, $user_name);

  # XXX This won't work for newly created hosts which lack a location.
  #      Needs to be smarter.
  #unless (grep /$serial/, @user_devices) {
  #  warning "$user_name not allowed to view device $serial or $serial does not exist";
  #  return status_401('unauthorized');
  #}
  try {
    $device_report = parse_device_report(body_parameters->as_hashref);
    ($device, $report_id) = record_device_report( schema, $device_report);
    connect_user_relay(schema, $user_name, $device_report->relay->{serial})
      if $device_report->relay;
  };
  if ($@) {
    chomp(my @err = $@->exceptions);
    return status_400("@err");
  }

  my $validation = validate_device(schema, $device, $device_report, $report_id);
  if ($validation) {
      status_200({
          device_id => $device->id,
          validated => \1,
          health    => $validation->{health},
          status    => "200"
      });
  }
  else {
    return status_500("error occurred in persisting device report");
  }
};


get '/device/:serial/location' => needs integrator => sub {
  my $user_name = session->read('integrator');
  my $serial    = param 'serial';

  my $device = lookup_device_for_user(schema, $serial, $user_name);
  return status_404("Device $serial not found") unless $device;

  my $location = device_rack_location(schema, $serial);

  return $location
    ? status_200($location)
    : status_409("Device $serial is not assigned to a rack");
};


post '/device/:serial/location' => needs integrator => sub {
  my $user_name = session->read('integrator');
  my $serial    = param 'serial';

  # XXX Input validation. Required fields.

  my $req    = body_parameters->as_hashref;
  my $result = update_device_location(schema, $req);

  if ($result) {
    status_200({
      device_id => $serial,
      action    => "update",
      status    => 200,
      moved_to  => "$req->{rack}:$req->{rack_unit}",
    });
  } else {
    return status_500({error => "error occured updating device location for $serial"});
  }
};

del '/device/:serial/location' => needs integrator => sub {
  my $user_name = session->read('integrator');
  my $serial    = param 'serial';

  my $req    = body_parameters->as_hashref;
  my $result = delete_device_location(schema, $req);


  if ($result) {
    status_200({
      device_id => $serial,
      action    => "delete",
      status    => 200,
      removed_from => "$req->{rack}:$req->{rack_unit}",
    });
  } else {
    return status_500({error => "error removing $serial from $req->{rack}:$req->{rack_unit}"});
  }
};


post '/device/:serial/profile' => needs integrator => sub {
  my $serial  = param 'serial';
  my $profile = body_parameters->as_hashref;
  my $product = determine_product(schema, $serial, $profile);

  if ($product) {
    status_200($product);
  } else {
    return status_500({error => "error occured determining product for $serial"});
  }
};

post '/device/:serial/settings' => needs integrator => sub {
  my $serial    = param 'serial';
  my $user_name = session->read('integrator');
  my $settings  = body_parameters->as_hashref;

  my $device = lookup_device_for_user(schema, $serial, $user_name);
  return status_404("Device $serial not found") unless $device;

  my $status = set_device_settings(schema, $device, $settings);

  if ($status) {
    return status_200({ status => "updated settings for " . $device->id });
  } else {
    return status_500({error => "error occured determining settings for $serial"});
  }
};

get '/device/:serial/settings' => needs integrator => sub {
  my $serial    = param 'serial';
  my $user_name = session->read('integrator');
  my $keys_only = param 'keys_only';

  my $device = lookup_device_for_user(schema, $serial, $user_name);
  return status_404("Device $serial not found") unless $device;
  my $settings = get_device_settings(schema, $device);

  if ($settings) {
    return $keys_only
      ? status_200([keys %{$settings}])
      : status_200($settings);
  } else {
    return status_500({error => "error occured determining settings for $serial"});
  }
};

post '/device/:serial/settings/:key' => needs integrator => sub {
  my $serial      = param 'serial';
  my $setting_key = param 'key';
  my $user_name   = session->read('integrator');
  my $setting     = body_parameters->as_hashref;

  my $device = lookup_device_for_user(schema, $serial, $user_name);
  return status_404("Device $serial not found") unless $device;

  my $setting_value = $setting->{$setting_key};
  return status_400("Setting key in request body must match name in the URL ('$setting_key')")
    unless $setting_value;
  my $status =
    process sub {set_device_setting(schema, $device, $setting_key, $setting_value)};

  if ($status) {
    return status_200({ status => "updated setting '$setting_key' for " . $device->id });
  } else {
    return status_500({error => "error occured determining setting for $serial"});
  }
};

get '/device/:serial/settings/:key' => needs integrator => sub {
  my $serial      = param 'serial';
  my $setting_key = param 'key';
  my $user_name   = session->read('integrator');

  my $device = lookup_device_for_user(schema, $serial, $user_name);
  return status_404("Device $serial not found") unless $device;
  my $setting = get_device_setting(schema, $device, $setting_key);

  if ($setting) {
    return status_200(
      {$setting_key => $setting->value}
    );
  } else {
    return status_404(
      {error => "No such setting '$setting_key' for Device $serial"}
    );
  }
};

post '/device/:serial/log' => needs integrator => sub {
  my $serial    = param 'serial';
  my $user_name = session->read('integrator');

  my $device = lookup_device_for_user(schema, $serial, $user_name);
  return status_404("Device $serial not found") unless $device;

  return status_400("Invalid JSON. Line breaks must be convereted to '\n' characters")
    unless %{ body_parameters->as_hashref };

  try {
    my $device_log = parse_device_log(body_parameters->as_hashref);
    record_device_log(schema, $device, $device_log);
  };

  if ($@) {
    my @err = $@->exceptions;
    return status_400("@err");
  }
  else {
    return status_200({ status => "Log written for device $serial." });
  }
};

get '/device/:serial/log' => needs integrator => sub {
  my $serial         = param 'serial';
  my $component_type = param 'component_type';
  my $component_id   = param 'component_id';
  my $limit          = param 'limit';
  my $user_name      = session->read('integrator');

  return status_400("'component_id' must be a UUID")
    if $component_id && ! is_uuid($component_id);
  return status_400("'limit' must be a positive number")
    unless !$limit || looks_like_number($limit) && $limit > 0;

  my $device = lookup_device_for_user(schema, $serial, $user_name);
  return status_404("Device $serial not found")
    unless $device;

  my @logs = get_device_logs(schema, $device, $component_type, $component_id, $limit);

  return status_200([@logs]);

};

1;
