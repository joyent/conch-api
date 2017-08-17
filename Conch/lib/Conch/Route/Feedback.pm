package Conch::Route::Feedback;

use strict;
use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport;
use Dancer2::Plugin::Passphrase;
use Dancer2::Plugin::REST;
use Hash::MultiValue;

use Data::Printer;

set serializer => 'JSON';

post '/feedback' => needs integrator => sub {
  status_200();
};

1;
