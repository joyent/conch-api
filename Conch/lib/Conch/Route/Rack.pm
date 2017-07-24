package Conch::Route::Rack;

use strict;

use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport;
use Dancer2::Plugin::REST;
use Hash::MultiValue;
use Conch::Control::Rack;

use Data::Printer;

set serializer => 'JSON';

# Return all devices an integrator user has access to
# Admins currently don't have access to endpoint and they get a 401.
# TODO: If we want to add admin access, what should this endpoint return? All
# devices across all DCs?
get '/rack' => needs integrator => sub {
  my $user_name = session->read('integrator');
  debug "Collecting racks for $user_name"; 
  my $racks;
  process sub { $racks = racks_for_user(schema, $user_name); };
  status_200({racks => ($racks || []) });
};

1;
