package Conch::Route::Rack;

use strict;
use warnings;

use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::REST;
use Dancer2::Plugin::RootURIFor;
use Hash::MultiValue;
use Conch::Control::Rack;
use Conch::Control::Device;
use Conch::Control::Workspace qw(
  get_user_workspace add_datacenter_rack_to_workspace
  remove_datacenter_rack_from_workspace
);

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

# Add rack to workspace by ID
post '/workspace/:wid/rack' => needs login => sub {
  my $user_id   = session->read('user_id');
  my $ws_id     = param 'wid';
  my $workspace = get_user_workspace( schema, $user_id, $ws_id );
  unless ( defined $workspace ) {
    return status_404("Workspace $ws_id not found");
  }

  my $rack_id = body_parameters->get('id');
  my $conflict = add_datacenter_rack_to_workspace( schema, $ws_id, $rack_id );

  return status_409($conflict) if defined($conflict);

  my %location = ( Location => root_uri_for "/workspace/$ws_id/rack/$rack_id" );
  response_header(%location);
  return status_303( \%location );
};

# Remove a rack from a workspace
del '/workspace/:wid/rack/:uuid' => needs login => sub {
  my $user_id   = session->read('user_id');
  my $ws_id     = param 'wid';
  my $workspace = get_user_workspace( schema, $user_id, $ws_id );
  unless ( defined $workspace ) {
    return status_404("Workspace $ws_id not found");
  }
  my $rack_id = param 'uuid';
  my $rack = workspace_rack( schema, $workspace->{id}, $rack_id );

  unless ( defined $rack ) {
    warning
      "User $user_id not allowed to view rack $rack_id or rack does not exist";
    return status_404("Rack $rack_id not found");
  }

  my $conflict =
    remove_datacenter_rack_from_workspace( schema, $ws_id, $rack_id );

  return status_409($conflict) if defined($conflict);

  return status_204();
};

# Returns a rack with layout.
get '/workspace/:wid/rack/:uuid' => needs login => sub {
  my $user_id   = session->read('user_id');
  my $ws_id     = param 'wid';
  my $workspace = get_user_workspace( schema, $user_id, $ws_id );
  unless ( defined $workspace ) {
    return status_404("Workspace $ws_id not found");
  }
  my $rack_id = param 'uuid';
  my $rack = workspace_rack( schema, $workspace->{id}, $rack_id );

  unless ( defined $rack ) {
    warning
      "User $user_id not allowed to view rack $rack_id or rack does not exist";
    return status_404("Rack $rack_id not found");
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
  my $rack_id = param 'uuid';

  my $layout = body_parameters->as_hashref;

  my $rack = workspace_rack( schema, $workspace->{id}, $rack_id );

  unless ( defined $rack ) {
    warning
      "User $user_id not allowed to view rack $rack_id or rack does not exist";
    return status_404("Rack $rack_id not found");
  }

  my @errors;
  my @updates;

  foreach my $k ( keys %{$layout} ) {
    my $update = {};
    $update->{device}    = $k;
    $update->{rack}      = $rack_id;
    $update->{rack_unit} = $layout->{$k};
    my ( $result, $err ) = update_device_location( schema, $update, $user_id );
    if ( defined $result ) {
      push @updates, $k;
    }
    else {
      push @errors, $err;
    }
  }

  status_200( { updated => \@updates, errors => \@errors } );
};

1;
