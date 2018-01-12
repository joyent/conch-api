package Conch::Plugin::Mail;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Conch::Mail;

sub register($self, $app, $conf) {
  $app->helper(mail => sub { $self } );
}

sub send_password_reset_email {
  shift;
  Conch::Mail::password_reset_email(@_);
}

sub send_new_user_invite {
  shift;
  Conch::Mail::new_user_invite(@_);
}

sub send_exiting_user_invite {
  shift;
  Conch::Mail::existing_user_invite(@_);
}


1;
