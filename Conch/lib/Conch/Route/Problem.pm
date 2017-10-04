package Conch::Route::Problem;

use strict;

use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Logger::LogAny;
use Dancer2::Plugin::REST;
use Hash::MultiValue;
use Conch::Control::Problem;

use Data::Printer;

set serializer => 'JSON';

get '/problem' => needs integrator => sub {
  my $user_name = session->read('integrator');
  my $problems = get_problems( schema, $user_name );
  status_200($problems);
};

# Not currently supported.
get '/problem/:uuid' => needs integrator => sub {
  my $user_name = session->read('integrator');
  status_200(
    { problem => "https://www.dropbox.com/s/55vth4g7yalc5u1/problem.jpg" } );
};

1;
