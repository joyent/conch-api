package Conch;
use Dancer2;
use Conch::Route::User;
use Conch::Route::Device;
use Conch::Route::Rack;
use Conch::Route::Relay;
use Conch::Route::Problem;
use Conch::Route::Feedback;

our $VERSION = '0.1';

get '/' => sub {
  send_file '/index.html'
};

true;
