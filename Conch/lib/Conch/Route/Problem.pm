package Conch::Route::Problem;

use strict;

use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport;
use Dancer2::Plugin::REST;
use Hash::MultiValue;
use Conch::Control::Problem;

use Data::Printer;

set serializer => 'JSON';

get '/problem' => needs integrator => sub {
  my $user_name = session->read('integrator');
  
  my $problems = get_problems(schema, $user_name);

  status_200($problems);
};

1;
