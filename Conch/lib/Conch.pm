package Conch;
use Dancer2;
use Conch::Route::User;
use Conch::Route::Device;
use Conch::Route::Rack;
use Conch::Route::Relay;
use Conch::Route::Problem;
use Conch::Route::Feedback;
use Conch::Route::Workspace;

our $VERSION = '2.0';

get '/' => sub {
  send_file '/index.html';
};

get '/doc' => sub {
  send_file '/doc/index.html';
};

true;
