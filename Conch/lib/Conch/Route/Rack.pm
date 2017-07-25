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

# Return all racks an integrator user has access to
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

# Returns defined rack roles.
get '/rack/role' => needs integrator => sub {
};

# Returns the layout for a given rack role, to help construct a rack map.
get '/rack/role/:uuid' => needs integrator => sub {
};

# Returns a rack with devices populated.
get '/rack/:uuid' => needs integrator => sub {
  # Verify this rack is assigned to the user.
  my $user_racks;
  process sub { $user_racks = racks_for_user(schema, $user_name); };
};

1;
