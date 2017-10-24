package Conch::Route::Workspace;

use strict;
use warnings;

use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::REST;
use Hash::MultiValue;
use Conch::Control::Workspace;

use Data::Printer;

set serializer => 'JSON';

get '/workspace' => needs login => sub {
  my $user_id = session->read('user_id');
  status_200();
  my $workspaces = get_user_workspaces( schema, $user_id );
  status_200($workspaces);
};

get '/workspace/:id' => needs login => sub {
  my $user_id = session->read('user_id');
  my $ws_id   = param 'id';
  my $workspace = get_user_workspace( schema, $user_id, $ws_id);
  status_200($workspace);
};

post '/workspace/:id/child' => needs login => sub {
  my $user_id = session->read('user_id');
  my $ws_id   = param 'id';
  my $name = body_parameters->get('name');
  my $description = body_parameters->get('description');
  unless (defined $name and defined $description) {
    return status_400("'name' and 'description' required");
  }
  my $subworkspace = create_sub_workspace( schema, $user_id, $ws_id, $name, $description);
  status_201($subworkspace);
};

1;
