package Conch;
use Dancer2;
use Conch::Route::Collect;

our $VERSION = '0.1';

get '/' => sub {
    template 'index' => { 'title' => 'Conch' };
};

true;
