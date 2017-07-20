package Conch::Route::User;

use strict;
use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::LogReport;
use Dancer2::Plugin::Passphrase;
use Dancer2::Plugin::REST;
use Hash::MultiValue;
use Conch::Control::User;
set serializer => 'JSON';

# Add an admin role that validates against a shared secret
Dancer2::Plugin::Auth::Tiny->extend(
  admin => sub {
    my ($auth, $coderef) = @_;
    return sub {
      if ( $auth->app->session->read("is_admin") ) {
        goto $coderef;
      }
      else {
        status_401('unauthorized');
      }
    };
  }
);

post '/user' => needs admin => sub {
  my $user;
  my $name = body_parameters->get('user');
  my $existingUser = lookup_user_by_name(schema, $name);

  if ($existingUser) {
    status_400("username already exists");
  }

  else {
    if (process sub {
      $user = create_integrator_user(schema, $name);
    })   { status_201($user); }
    else { status_500('unable to create a user'); }
  }

};


post '/login' => sub {
  my $username = body_parameters->get('user');
  my $password = body_parameters->get('password');
  if ($username eq 'admin' &&
    passphrase($password)->matches(config->{'admin_password'}))
  {
    session is_admin => 1;
    status_200({role => "admin"});
  }
  elsif (authenticate(schema, $username, $password)) {
    session user => $username;
    status_200();
  }
  else {
    status_404 "failed_log_in";
  }
};

1;
