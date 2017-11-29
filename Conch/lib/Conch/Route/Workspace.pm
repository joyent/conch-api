package Conch::Route::Workspace;

use strict;
use warnings;

use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::REST;
use Hash::MultiValue;
use Conch::Control::Workspace;
use Conch::Control::Role;
use Conch::Mail;

use Data::Printer;

set serializer => 'JSON';

get '/workspace' => needs login => sub {
  my $user_id = session->read('user_id');
  my $workspaces = get_user_workspaces( schema, $user_id );
  status_200($workspaces);
};

get '/workspace/:id' => needs login => sub {
  my $user_id   = session->read('user_id');
  my $ws_id     = param 'id';
  my $workspace = get_user_workspace( schema, $user_id, $ws_id );
  unless ( defined $workspace ) {
    return status_404("Workspace $ws_id not found");
  }
  status_200($workspace);
};

post '/workspace/:id/child' => needs login => sub {
  my $user_id     = session->read('user_id');
  my $ws_id       = param 'id';
  my $name        = body_parameters->get('name');
  my $description = body_parameters->get('description');
  unless ( defined $name and defined $description ) {
    return status_400("'name' and 'description' required");
  }
  my $subworkspace =
    create_sub_workspace( schema, $user_id, $ws_id, $name, $description );
  status_201($subworkspace);
};

get '/workspace/:id/child' => needs login => sub {
  my $user_id       = session->read('user_id');
  my $ws_id         = param 'id';
  my $subworkspaces = get_sub_workspaces( schema, $user_id, $ws_id );
  status_200($subworkspaces);
};

post '/workspace/:id/user' => needs login => sub {
  my $user_id = session->read('user_id');
  my $ws_id   = param 'id';

  my $email = body_parameters->get('email');
  my $role  = body_parameters->get('role');

  unless ( defined $email and defined $role ) {
    return status_400("'email' and 'role' required");
  }

  my $workspace = get_user_workspace( schema, $user_id, $ws_id );
  unless ( defined $workspace ) {
    return status_404("Workspace $ws_id not found");
  }

  my $valid_roles = assignable_roles( $workspace->{role} );
  unless ( defined($valid_roles) ) {
    return status_401(
      "You do not have sufficient privileges to invite users this workspace" );
  }
  unless ( grep /^$role$/, @$valid_roles ) {
    return status_400(
      "'role' must be one of: " . join( ', ', @$valid_roles ) );
  }

  my $user =
    invite_user_to_workspace( schema, $workspace, $email, $role,
    \&new_user_invite, \&existing_user_invite );
  status_200($user);
};

get '/workspace/:id/user' => needs login => sub {
  my $user_id   = session->read('user_id');
  my $ws_id     = param 'id';
  my $workspace = get_user_workspace( schema, $user_id, $ws_id );
  unless ( defined $workspace ) {
    return status_404("Workspace $ws_id not found");
  }
  my $users = workspace_users( schema, $workspace->{id} );
  status_200($users);
};

put '/workspace/:id/room' => needs login => sub {
  my $user_id   = session->read('user_id');
  my $ws_id     = param 'id';
  my $workspace = get_user_workspace( schema, $user_id, $ws_id );
  unless ( defined $workspace ) {
    return status_404("Workspace $ws_id not found");
  }
  if ( $workspace->{name} eq 'GLOBAL' ) {
    return status_400('Cannot modify GLOBAL workspace');
  }
  unless ( $workspace->{role} eq 'Administrator' ) {
    return status_401('Only adminstrators may update the datacenter roles');
  }
  unless ( request->body ) {
    return status_400("Array of datacenter room IDs required in request");
  }
  my $room_ids = decode_json( request->body ) || {};
  unless ( ref($room_ids) eq 'ARRAY' ) {
    return status_400("Array of datacenter room IDs required in request");
  }
  my ( $rooms, $conflict ) =
    replace_workspace_rooms( schema, $workspace->{id}, $room_ids );

  if ( defined $conflict ) { return status_409($conflict); }
  status_200($rooms);
};

get '/workspace/:id/room' => needs login => sub {
  my $user_id   = session->read('user_id');
  my $ws_id     = param 'id';
  my $workspace = get_user_workspace( schema, $user_id, $ws_id );
  unless ( defined $workspace ) {
    return status_404("Workspace $ws_id not found");
  }
  my $rooms = get_workspace_rooms( schema, $workspace->{id} );
  status_200($rooms);
};

1;
