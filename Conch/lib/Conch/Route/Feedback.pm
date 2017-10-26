package Conch::Route::Feedback;

use strict;
use warnings;

use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Passphrase;
use Dancer2::Plugin::REST;
use Hash::MultiValue;

use Data::Printer;
use Log::Any;

set serializer => 'JSON';

post '/feedback' => needs login => sub {
  my $user_id = session->read('user_id');
  my $message = param 'message';
  my $subject = param 'subject';

  Log::Any->get_logger( category => "user.feedback" )->critical(
    {
      user     => $user_id,
      feedback => $message,
      subject  => $subject
    }
  );

  status_200();
};

1;
