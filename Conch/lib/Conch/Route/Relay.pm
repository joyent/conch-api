package Conch::Route::Relay;

use strict;

use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport;
use Dancer2::Plugin::REST;
use Hash::MultiValue;
use Conch::Control::Relay;

use Data::Printer;

set serializer => 'JSON';

# Returns all relay devices and their status.
get '/relay' => needs admin => sub {
  my $relays = list_relays(schema);
  status_200($relays);
};

# Returns all active relay devices and their status.
get '/relay/active' => needs admin => sub {
  my $relays = list_relays(schema, 2);
  status_200($relays);
};

# This acts as both an initial registration and heartbeat endpoint.
post '/relay/:serial/register' => needs integrator => sub {
  my $ip = request->address;
  my $serial = param 'serial';
  my $user_name = session->read('integrator');
  my $attrib = body_parameters->as_hashref;

  # XXX Attribute validation.

  my $relay = process sub {
    connect_user_relay(schema, $user_name, $serial);
    return register_relay(schema, $serial, $ip, $attrib)
  };

  if ($relay) {
    status_200({
      relay => $serial,
      registered => \1,
    });
  } else {
    status_500({
      relay => $serial,
      registered => \0,
      error => "error while registering $serial",
    });
  }
};

1;
