package Conch::Route::Feedback;

use strict;
use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport;
use Dancer2::Plugin::Passphrase;
use Dancer2::Plugin::REST;
use Hash::MultiValue;
use Mail::Sendmail;

use Data::Printer;

set serializer => 'JSON';

post '/feedback' => needs integrator => sub {
  my $user_name = session->read('integrator');
  my $message   = param 'message';
  my $subject   = param 'subject';
  my %mail      = (
    To      => 'preflight-dev@joyent.com',
    From    => 'preflight-dev@joyent.com',
    Subject => "From user $user_name: $subject",
    Message => "$message"
  );
  if ( sendmail %mail ) {
    info "Feedback email sent.";
  }
  else {
    warning "Sendmail error: $Mail::Sendmail::error";
    return status_500("could not send feedback");
  }
  status_200();
};

1;
