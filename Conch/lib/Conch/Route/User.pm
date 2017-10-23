package Conch::Route::User;

use strict;
use warnings;

use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Passphrase;
use Dancer2::Plugin::REST;
use Hash::MultiValue;

use Conch::Control::User;
use Conch::Control::User::Setting;
use Conch::Control::Datacenter;

use Data::Printer;
set serializer => 'JSON';

# Add an admin role that validates against a shared secret
Dancer2::Plugin::Auth::Tiny->extend(
  admin => sub {
    my ( $auth, $coderef ) = @_;
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
    my ( $auth, $coderef ) = @_;
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
  my $existingUser = lookup_user_by_name( schema, $name );

  if ($existingUser) {
    status_400("username already exists");
  }

  else {
    $user = create_integrator_user( schema, $name );
    if ($user) {
      status_201($user);
    }
    else { status_500('unable to create a user'); }
  }

};

post '/user/me/settings' => needs integrator => sub {
  my $user_name = session->read('integrator');
  my $settings  = body_parameters->as_hashref;

  return status_400("No settings specified or invalid JSON given")
    unless $settings;

  my $user = lookup_user_by_name( schema, $user_name );
  my $status = set_user_settings( schema, $user, $settings );

  if ($status) {
    return status_200( { status => "updated settings for user" } );
  }
  else {
    return status_500(
      { error => "error occured determining settings for user" } );
  }
};

get '/user/me/settings' => needs integrator => sub {
  my $user_name = session->read('integrator');
  my $keys_only = param 'keys_only';

  my $user = lookup_user_by_name( schema, $user_name );
  my $settings = get_user_settings( schema, $user );

  if ($settings) {
    return $keys_only
      ? status_200( [ keys %{$settings} ] )
      : status_200($settings);
  }
  else {
    return status_500(
      { error => "error occured determining settings for user" } );
  }
};

post '/user/me/settings/:key' => needs integrator => sub {
  my $setting_key = param 'key';
  my $user_name   = session->read('integrator');
  my $setting     = body_parameters->as_hashref;

  my $setting_value = $setting->{$setting_key};

  return status_400(
    "Setting key in request body must match name in the URL ('$setting_key')")
    unless defined $setting_value;

  my $user = lookup_user_by_name( schema, $user_name );
  my $status = set_user_setting( schema, $user, $setting_key, $setting_value );

  if ($status) {
    return status_200(
      { status => "updated setting '$setting_key' for user" } );
  }
  else {
    return status_500(
      { error => "error occured determining setting for user" } );
  }
};

get '/user/me/settings/:key' => needs integrator => sub {
  my $setting_key = param 'key';
  my $user_name   = session->read('integrator');

  my $user = lookup_user_by_name( schema, $user_name );
  my $setting = get_user_setting( schema, $user, $setting_key );

  if ($setting) {
    return status_200($setting);
  }
  else {
    return status_404( { error => "No such setting '$setting_key'" } );
  }
};

del '/user/me/settings/:key' => needs integrator => sub {
  my $setting_key = param 'key';
  my $user_name   = session->read('integrator');

  my $user = lookup_user_by_name( schema, $user_name );
  my $deleted = delete_user_setting( schema, $user, $setting_key );

  if ($deleted) {
    return status_200(
      { "status" => "deleted setting '$setting_key' for user" } );
  }
  else {
    return status_404("setting '$setting_key' does not exist");
  }

};

post '/login' => sub {

  my $username = body_parameters->get('user');
  my $password = body_parameters->get('password');
  unless ( defined $username && defined $password ) {
    return status_400("'user' and 'password' must be specified");
  }

  if ( $username eq 'admin'
    && passphrase($password)->matches( config->{'admin_password'} ) )
  {
    session is_admin => 1;
    info "admin logged in";
    status_200( { role => "admin" } );
  }
  elsif ( authenticate( schema, $username, $password ) ) {
    session integrator => $username;
    info "integrator '$username' logged in";
    status_200( { role => "integrator" } );
  }
  else {
    status_401 "failed log in attempt";
  }
};

post '/logout' => sub {
  session->delete('is_admin');
  session->delete('integrator');
  status_200( { status => "logged out" } );
};

post '/datacenter_access' => sub {
  if (
    # XXX This is truncating what we're passing in as an array for some reason.
    # XXX Only the last value makes it in.
    set_datacenter_room_access( schema, body_parameters->as_hashref )
    )
  {
    status_200();
  }
  else { status_500('error setting user datacenter access'); }
};

1;
