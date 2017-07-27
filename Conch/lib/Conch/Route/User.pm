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
use Conch::Control::Datacenter;
use Data::Printer;
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
  },
  integrator => sub {
    my ($auth, $coderef) = @_;
    return sub {
      if ( $auth->app->session->read('integrator') ) {
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
  header 'Access-Control-Allow-Origin' => '*';
  my $username = body_parameters->get('user');
  my $password = body_parameters->get('password');
  if ($username eq 'admin' &&
    passphrase($password)->matches(config->{'admin_password'}))
  {
    session is_admin => 1;
    info "admin logged in";
    status_200({role => "admin"});
  }
  elsif (authenticate(schema, $username, $password)) {
    session integrator => $username;
    info "integrator '$username' logged in";
    status_200({role => "integrator"});
  }
  else {
    status_401 "failed log in attempt";
  }
};

post '/datacenter_access' => sub {
  if (process sub {
    # XXX This is truncating what we're passing in as an array for some reason.
    # XXX Only the last value makes it in.
    set_datacenter_room_access(schema, body_parameters->as_hashref)
  })    { status_200(); }
   else { status_500('error setting user datacenter access'); }
};

1;
