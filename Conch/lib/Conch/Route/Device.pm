package Conch::Route::Device;

use strict;

use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport;
use Dancer2::Plugin::REST;
use Hash::MultiValue;
use Conch::Control::Device;
use Conch::Control::DeviceReport;
use Conch::Control::Device::Validation;
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
  # XXX I don't understand the process call here, but it's interfering with
  # XXX error checking later on. -- bdha
  #process sub { @devices = devices_for_user(schema, $user_name); };
  @devices = devices_for_user(schema, $user_name);
  
  status_200(\@devices || []);
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

  # XXX Move this to Conch::Control::check_device_access(schema, $user_name, $serial);
  # Verify the requested device is accessible to this user.
  my @user_devices;
  @user_devices = devices_for_user(schema, $user_name);

  unless (grep /$serial/, @user_devices) {
    warning "$user_name not allowed to view device $serial or $serial does not exist";
    return status_401('unauthorized');
  }

  my ($report_id, $device_report ) = device_inventory(schema, $serial);
  my @validation_report = device_validation_report(schema, $report_id);

  $device_report->{validation} = \@validation_report;

  # XXX Conch::Data::DeviceReport is sticking its __CLASS__ where it's not wanted.
  my $cleanup = delete $device_report->{"__CLASS__"};

  status_200($device_report || []);
};

post '/device/:serial' => needs integrator => sub {
  my $user_name = session->read('integrator');
  my $serial    = param 'serial';

  my $device;
  my $report_id;

  # 
  # NOTE This stops reports being ingested until the device is slotted into a rack.
  #      This may not be desireable. Once the device is entered into device_location
  #      via /rack/:rackid, reports can be consumed. This checks does stop, in theory,
  #      people from submitting reports for hosts they don't control.

  # XXX Move this to Conch::Control::check_device_access(schema, $user_name, $serial);
  # Verify the requested device is accessible to this user.
  my @user_devices;
  #process sub { @user_devices = devices_for_user(schema, $user_name); };
  @user_devices = devices_for_user(schema, $user_name);

  # XXX This won't work for newly created hosts which lack a location.
  #      Needs to be smarter.
  #unless (grep /$serial/, @user_devices) {
  #  warning "$user_name not allowed to view device $serial or $serial does not exist";
  #  return status_401('unauthorized');
  #}

  process sub {
    my $device_report = parse_device_report(body_parameters->as_hashref);
    ($device, $report_id) = record_device_report( schema, $device_report);
    associate_relay(schema, $user_name, $device_report->relay->{serial});
  };

  # XXX validate_device needs to return more context, or "validated" in the
  #     response is a rubber stamp.
  my $store_report = validate_device(schema, $device, $report_id);
  if ($store_report) {
      status_200({
          device_id => $device->id,
          validated => \1,
          action    => "report",
          status    => "200"
      });
  }
  else {
    return status_500("error occurred in persisting device report");
  }
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

1;
