package Conch::Route::Relay;

use strict;
use warnings;

use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::REST;
use Hash::MultiValue;
use Conch::Control::Relay;

use Data::Printer;

set serializer => 'JSON';

get '/workspace/:wid/relay' => needs login => sub {
  my $ws_id  = param 'wid';
  my $relays;
  if (param 'active') {
    $relays = list_workspace_relays( schema, $ws_id, 2);
  }
  else {
    $relays = list_workspace_relays( schema, $ws_id );
  }
  status_200( $relays );
};

# This acts as both an initial registration and heartbeat endpoint.
post '/relay/:serial/register' => needs login => sub {
  my $client_ip = request->address;
  my $serial    = param 'serial';
  my $user_id   = session->read('user_id');
  my $attrib    = body_parameters->as_hashref;

  # XXX Attribute validation.

  my $relay = register_relay( schema, $serial, $client_ip, $attrib );
  connect_user_relay( schema, $user_id, $serial );

  if ($relay) {
    status_200(
      {
        relay      => $serial,
        registered => \1,
      }
    );
  }
  else {
    status_500(
      {
        relay      => $serial,
        registered => \0,
        error      => "error while registering $serial",
      }
    );
  }
};

1;
