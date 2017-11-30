package Conch::Route::Device;

use strict;
use warnings;

use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::REST;
use Dancer2::Plugin::RootURIFor;
use Hash::MultiValue;
use Data::Validate::UUID 'is_uuid';
use Scalar::Util 'looks_like_number';
use List::Util 'reduce';

use Conch::Control::Device::Profile;
use Conch::Control::Device::Validation;
use Conch::Control::Device::Log;
use Conch::Control::Device;
use Conch::Control::DeviceReport;
use Conch::Control::Relay;
use Conch::Control::Workspace 'get_user_workspace';

use Data::Printer;
use Log::Any;

set serializer => 'JSON';

get '/workspace/:wid/device' => needs login => sub {
  my $user_id   = session->read('user_id');
  my $ws_id     = param 'wid';
  my $workspace = get_user_workspace( schema, $user_id, $ws_id );
  unless ( defined $workspace ) {
    return status_404("Workspace $ws_id not found");
  }

  # set of response filters based on the presence and values of query parameters
  my @query_filters;
  push @query_filters, sub { $_[0] if defined( $_[0]->{graduated} ); }
    if defined( param 'graduated' ) and ( param 'graudated ' ) eq 't';
  push @query_filters, sub { $_[0] if !defined( $_[0]->{graduated} ); }
    if defined( param 'graduated' ) and ( param 'graudated ' ) eq 'f';
  push @query_filters,
    sub { $_[0] if uc( $_[0]->{health} ) eq uc( param 'health' ); }
    if defined( param 'health' );

  # transform result from hashes to single string field, should be added last
  push @query_filters, sub { $_[0]->{id}; }
    if param 'ids_only';

  my @devices;
  for my $d (
    unlocated_devices( schema, $user_id ),
    workspace_devices( schema, $workspace->{id} )
    )
  {
    my %data = $d->get_columns;
    my $device = reduce { $b->($a) if $a } \%data, @query_filters;
    push @devices, $device if $device;
  }

  return status_200( \@devices );
};

get '/workspace/:wid/device/active' => needs login => sub {
  my $user_id   = session->read('user_id');
  my $ws_id     = param 'wid';
  my $workspace = get_user_workspace( schema, $user_id, $ws_id );
  unless ( defined $workspace ) {
    return status_404("Workspace $ws_id not found");
  }

  my @devices = map {
    { $_->get_columns }
  } get_active_devices( schema, $user_id, $workspace->{id} );
  status_200( \@devices );
};

get '/workspace/:wid/device/health/:state' => needs login => sub {
  my $user_id   = session->read('user_id');
  my $ws_id     = param 'wid';
  my $workspace = get_user_workspace( schema, $user_id, $ws_id );
  unless ( defined $workspace ) {
    return status_404("Workspace $ws_id not found");
  }

  my $state = param 'state';
  if ( $state !~ /PASS|FAIL/ ) {
    return status_400("/device/health/:state must be PASS or FAIL");
  }

  my @devices = map {
    { $_->get_columns }
  } get_devices_by_health( schema, $user_id, $workspace->{id}, $state );

  status_200( \@devices );
};

get '/device/:serial' => needs login => sub {
  my $user_id = session->read('user_id');
  my $serial  = param 'serial';

  my $device = lookup_device_for_user( schema, $serial, $user_id );

  unless ($device) {
    warning
      "$user_id not allowed to view device $serial or $serial does not exist";
    return status_404('Device not found');
  }

  my @validations   = ();
  my $report        = {};
  my $device_report = latest_device_report( schema, $serial );
  if ($device_report) {
    @validations = device_validation_report( schema, $device_report->id );
    $report = from_json( $device_report->report );
    delete $report->{'__CLASS__'};
  }

  my $location = device_rack_location( schema, $serial );
  my @nics = device_nic_neighbors( schema, $serial );

  my $response = { $device->get_columns };
  $response->{latest_report} = $report;
  $response->{validations}   = \@validations;
  $response->{nics}          = \@nics;
  $response->{location}      = $location;

  status_200($response);
};

post '/device/:serial' => needs login => sub {
  my $user_id = session->read('user_id');
  my $serial  = param 'serial';

  my ( $device, $report_id );

# NOTE This stops reports being ingested until the device is slotted into a rack.
#      This may not be desireable. Once the device is entered into device_location
#      via /rack/:rackid, reports can be consumed. This checks does stop, in theory,
#      people from submitting reports for hosts they don't control.

  my $raw_report = body_parameters->as_hashref;
  Log::Any->get_logger( category => 'report.raw' )
    ->trace( encode_json $raw_report);

  my ( $device_report, $parse_err ) = parse_device_report($raw_report);

  if ($parse_err) {
    my $err_log = Log::Any->get_logger( category => 'report.unparsable' );
    $err_log->crit("Failed to parse report: $parse_err");
    $err_log->trace( encode_json $raw_report );
    return status_400("$parse_err");
  }

  eval {
    ( $device, $report_id ) = record_device_report( schema, $device_report );
  };
  if ($@) {
    my $err_log = Log::Any->get_logger( category => 'report.error' );
    $err_log->crit("Failed to persist report: $@");
    $err_log->trace( encode_json $raw_report );
    return status_500("$@");
  }

  connect_user_relay( schema, $user_id, $device_report->relay->{serial} )
    if $device_report->relay;

  my $validation =
    validate_device( schema, $device, $device_report, $report_id );
  if ($validation) {
    status_200(
      {
        device_id => $device->id,
        validated => \1,
        health    => $validation->{health},
        status    => "200"
      }
    );
  }
  else {
    return status_500("error occurred in persisting device report");
  }
};

get '/device/:serial/location' => needs login => sub {
  my $user_id = session->read('user_id');
  my $serial  = param 'serial';

  my $device = lookup_device_for_user( schema, $serial, $user_id );
  return status_404("Device $serial not found") unless $device;

  my $location = device_rack_location( schema, $serial );

  return $location
    ? status_200($location)
    : status_409("Device $serial is not assigned to a rack");
};

post '/device/:serial/location' => needs login => sub {
  my $user_id = session->read('user_id');
  my $serial  = param 'serial';

  # XXX Input validation. Required fields.

  my $req = body_parameters->as_hashref;
  my ( $result, $err ) = update_device_location( schema, $req, $user_id );

  if ($err) {
    return status_500(
      { error => "error occured updating device location for $serial: $err" } );
  }

  status_200(
    {
      device_id => $serial,
      action    => "update",
      status    => 200,
      moved_to  => "$req->{rack}:$req->{rack_unit}",
    }
  );
};

del '/device/:serial/location' => needs login => sub {
  my $user_id = session->read('user_id');
  my $serial  = param 'serial';

  my $req = body_parameters->as_hashref;
  my $result = delete_device_location( schema, $req );

  if ($result) {
    status_200(
      {
        device_id    => $serial,
        action       => "delete",
        status       => 200,
        removed_from => "$req->{rack}:$req->{rack_unit}",
      }
    );
  }
  else {
    return status_500(
      {
        error => sprintf(
          "error removing $serial from %s:%s",
          $req->{rack}, $req->{rack_unit}
        )
      }
    );
  }
};

post '/device/:serial/profile' => needs login => sub {
  my $serial  = param 'serial';
  my $profile = body_parameters->as_hashref;
  my $product = determine_product( schema, $serial, $profile );

  if ($product) {
    status_200($product);
  }
  else {
    return status_500(
      { error => "error occured determining product for $serial" } );
  }
};

post '/device/:serial/settings' => needs login => sub {
  my $user_id  = session->read('user_id');
  my $serial   = param 'serial';
  my $settings = body_parameters->as_hashref;

  my $device = lookup_device_for_user( schema, $serial, $user_id );
  return status_404("Device $serial not found") unless $device;

  my $status = set_device_settings( schema, $device, $settings );

  if ($status) {
    return status_200( { status => "updated settings for " . $device->id } );
  }
  else {
    return status_500(
      { error => "error occured determining settings for $serial" } );
  }
};

get '/device/:serial/settings' => needs login => sub {
  my $serial    = param 'serial';
  my $user_id   = session->read('user_id');
  my $keys_only = param 'keys_only';

  my $device = lookup_device_for_user( schema, $serial, $user_id );
  return status_404("Device $serial not found") unless $device;
  my $settings = get_device_settings( schema, $device );

  if ($settings) {
    return $keys_only
      ? status_200( [ keys %{$settings} ] )
      : status_200($settings);
  }
  else {
    return status_500(
      { error => "error occured determining settings for $serial" } );
  }
};

post '/device/:serial/settings/:key' => needs login => sub {
  my $serial      = param 'serial';
  my $setting_key = param 'key';
  my $user_id     = session->read('user_id');
  my $setting     = body_parameters->as_hashref;

  my $device = lookup_device_for_user( schema, $serial, $user_id );
  return status_404("Device $serial not found") unless $device;

  my $setting_value = $setting->{$setting_key};
  return status_400(
    "Setting key in request body must match name in the URL ('$setting_key')")
    unless defined $setting_value;

  my $status =
    set_device_setting( schema, $device, $setting_key, $setting_value );

  if ($status) {
    return status_200(
      { status => "updated setting '$setting_key' for " . $device->id } );
  }
  else {
    return status_500(
      { error => "error occured determining setting for $serial" } );
  }
};

del '/device/:serial/settings/:key' => needs login => sub {
  my $serial      = param 'serial';
  my $setting_key = param 'key';
  my $user_id     = session->read('user_id');

  my $device = lookup_device_for_user( schema, $serial, $user_id );
  return status_404("Device $serial not found") unless $device;
  my $setting = delete_device_setting( schema, $device, $setting_key );

  if ($setting) {
    return status_200(
      { status => "Deleted setting '$setting_key' for Device $serial" } );
  }
  else {
    return status_404(
      { error => "No such setting '$setting_key' for Device $serial" } );
  }
};

get '/device/:serial/settings/:key' => needs login => sub {
  my $serial      = param 'serial';
  my $setting_key = param 'key';
  my $user_id     = session->read('user_id');

  my $device = lookup_device_for_user( schema, $serial, $user_id );
  return status_404("Device $serial not found") unless $device;
  my $setting = get_device_setting( schema, $device, $setting_key );

  if ($setting) {
    return status_200( { $setting_key => $setting->value } );
  }
  else {
    return status_404(
      { error => "No such setting '$setting_key' for Device $serial" } );
  }
};

post '/device/:serial/log' => needs login => sub {
  my $serial  = param 'serial';
  my $user_id = session->read('user_id');

  my $device = lookup_device_for_user( schema, $serial, $user_id );
  return status_404("Device $serial not found") unless $device;

  return status_400(
    "Invalid JSON. Line breaks must be convereted to '\n' characters")
    unless %{ body_parameters->as_hashref };

  my ( $device_log, $valid_err ) =
    parse_device_log( body_parameters->as_hashref );
  if ($valid_err) {
    return status_400("$valid_err");
  }
  record_device_log( schema, $device, $device_log );
  return status_200( { status => "Log written for device $serial." } );
};

get '/device/:serial/log' => needs login => sub {
  my $serial         = param 'serial';
  my $component_type = param 'component_type';
  my $component_id   = param 'component_id';
  my $limit          = param 'limit';
  my $user_id        = session->read('user_id');

  return status_400("'component_id' must be a UUID")
    if $component_id && !is_uuid($component_id);
  return status_400("'limit' must be a positive number")
    unless !$limit || looks_like_number($limit) && $limit > 0;

  my $device = lookup_device_for_user( schema, $serial, $user_id );
  return status_404("Device $serial not found")
    unless $device;

  my @logs =
    get_device_logs( schema, $device, $component_type, $component_id, $limit );

  return status_200( [@logs] );

};

post '/device/:serial/graduate' => needs login => sub {
  my $user_id = session->read('user_id');
  my $serial  = param 'serial';

  my $device = lookup_device_for_user( schema, $serial, $user_id );
  return status_404("Device $serial not found") unless $device;

  return status_409("Device $serial has already been graduated")
    if defined( $device->graduated );

  graduate_device( schema, $device->id );

  my %location = ( Location => root_uri_for "/device/$serial" );
  response_header %location;
  return status_303( \%location );
};

post '/device/:serial/triton_reboot' => needs login => sub {
  my $user_id = session->read('user_id');
  my $serial  = param 'serial';

  my $device = lookup_device_for_user( schema, $serial, $user_id );
  return status_404("Device $serial not found") unless $device;

  triton_reboot_device( schema, $device->id );

  my %location = ( Location => root_uri_for "/device/$serial" );
  response_header(%location);
  return status_303( \%location );
};

post '/device/:serial/triton_uuid' => needs login => sub {
  my $user_id = session->read('user_id');
  my $serial  = param 'serial';

  my $device = lookup_device_for_user( schema, $serial, $user_id );
  return status_404("Device $serial not found") unless $device;

  my $triton_uuid   = param 'triton_uuid';
  return status_400("'triton_uuid' must be present and a UUID")
    unless defined($triton_uuid) && is_uuid($triton_uuid);

  set_triton_uuid( schema, $device->id, $triton_uuid );

  my %location = ( Location => root_uri_for "/device/$serial" );
  response_header(%location);
  return status_303( \%location );
};


1;
