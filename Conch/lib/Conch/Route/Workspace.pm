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

1;
