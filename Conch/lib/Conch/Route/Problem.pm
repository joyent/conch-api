package Conch::Route::Problem;

use strict;
use warnings;

use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::REST;
use Hash::MultiValue;
use Conch::Control::Problem;
use Conch::Control::Workspace 'get_user_workspace';

use Data::Printer;

set serializer => 'JSON';

get '/workspace/:wid/problem' => needs login => sub {
  my $user_id   = session->read('user_id');
  my $ws_id     = param 'wid';
  my $workspace = get_user_workspace( schema, $user_id, $ws_id );
  unless ( defined $workspace ) {
    return status_404("Workspace $ws_id not found");
  }
  my $problems = get_problems( schema, $user_id, $workspace->{id} );
  status_200($problems);
};


1;
