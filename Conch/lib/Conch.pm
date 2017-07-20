package Conch;
use Dancer2;
use Conch::Route::DeviceReport;
use Conch::Route::User;

our $VERSION = '0.1';

get '/' => sub {
    template 'index' => { 'title' => 'Conch' };
};

true;
