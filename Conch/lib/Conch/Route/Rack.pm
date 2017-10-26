package Conch::Route::Rack;

use strict;
use warnings;

use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::REST;
use Hash::MultiValue;
use Conch::Control::Rack;
use Conch::Control::Device;
use Conch::Control::Workspace 'get_user_workspace';

use List::MoreUtils;
use Data::Printer;

set serializer => 'JSON';

# Return all racks in a workspace
get '/workspace/:wid/rack' => needs login => sub {
  my $user_id   = session->read('user_id');
  my $ws_id     = param 'wid';
  my $workspace = get_user_workspace( schema, $user_id, $ws_id );
  unless ( defined $workspace ) {
    return status_404("Workspace $ws_id not found");
  }
  my $racks = workspace_racks( schema, $workspace->{id} );
  status_200($racks);
};

get '/rack-role' => needs login => sub {
  my @roles = values %{ rack_roles(schema) };
  status_200( \@roles );
};

# Returns a rack with layout.
get '/workspace/:wid/rack/:uuid' => needs login => sub {
  my $user_id   = session->read('user_id');
  my $ws_id     = param 'wid';
  my $workspace = get_user_workspace( schema, $user_id, $ws_id );
  unless ( defined $workspace ) {
    return status_404("Workspace $ws_id not found");
  }
  my $uuid = param 'uuid';
  my $rack = workspace_rack( schema, $workspace->{id}, $uuid );

  unless ( defined $rack ) {
    warning
      "User $user_id not allowed to view rack $uuid or rack does not exist";
    return status_404("Rack $uuid not found");
  }

  my $layout = rack_layout( schema, $rack );

  return status_200($layout);
};

# Bulk update a rack layout.
# XXX This should be wrapped in a txn. With real error messages.
post '/workspace/:wid/rack/:uuid/layout' => needs login => sub {
  my $user_id   = session->read('user_id');
  my $ws_id     = param 'wid';
  my $workspace = get_user_workspace( schema, $user_id, $ws_id );
  unless ( defined $workspace ) {
    return status_404("Workspace $ws_id not found");
  }
  my $uuid = param 'uuid';

  my $layout = body_parameters->as_hashref;

  my $rack = workspace_rack( schema, $workspace->{id}, $uuid );

  unless ( defined $rack ) {
    warning
      "User $user_id not allowed to view rack $uuid or rack does not exist";
    return status_404("Rack $uuid not found");
  }

  my @errors;
  my @updates;

  foreach my $k ( keys %{$layout} ) {
    my $update = {};
    $update->{device}    = $k;
    $update->{rack}      = $uuid;
    $update->{rack_unit} = $layout->{$k};
    my $result = update_device_location( schema, $update, $user_id );
    if ($result) {
      push @updates, $k;
    }
    else {
      push @errors, $k;
    }
  }

  status_200( { updated => \@updates, errors => \@errors } );
};

1;
