package Conch::Route::User;

use strict;
use warnings;

use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Auth::Tiny;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Passphrase;
use Dancer2::Plugin::REST;
use Hash::MultiValue;
use HTTP::Headers::ActionPack::Authorization::Basic;

use Conch::Control::User;
use Conch::Mail qw( password_reset_email );
use Conch::Control::User::Setting;

use Data::Printer;
set serializer => 'JSON';

Dancer2::Plugin::Auth::Tiny->extend(
  login => sub {
    my ( $auth, $coderef ) = @_;
    return sub {
      my $user_id = $auth->app->session->read('user_id');
      if ( $user_id && validate_user_id( schema, $user_id ) ) {
        goto $coderef;
      }

      my $auth_header = $auth->app->request->header('Authorization');
      if ( defined($auth_header) ) {
        my $cred =
          HTTP::Headers::ActionPack::Authorization::Basic->new_from_string(
          $auth_header);
        my $user = authenticate( schema, $cred->username, $cred->password );
        if ( defined($user) ) {
          $auth->app->session->write( user_id => $user->id );
          goto $coderef;
        }
      }
      status_401('unauthorized');
    };
  }
);

post '/login' => sub {

  my $username = body_parameters->get('user');
  my $password = body_parameters->get('password');
  unless ( defined $username && defined $password ) {
    return status_400("'user' and 'password' must be specified");
  }

  my $user = authenticate( schema, $username, $password );
  unless ( defined $user ) {
    return status_401 "failed log in attempt";
  }
  my $user_id = $user->id;
  session user_id => $user_id;
  info("User $user_id '$username' logged in");

  status_200( { status => "logged in" } );
};

post '/logout' => sub {
  session->destroy_session;
  status_200( { status => "logged out" } );
};

post '/reset_password' => sub {
  my $username = body_parameters->get('email');
  unless ( defined $email ) {
    return status_400("'email' must be specified");
  }
  reset_user_password( schema, $email, \&password_reset_email );

  # always return 200 whether or not the user exists so no information about
  # the status of a user is given
  status_200();
};

# used to check if the current user is authenticated
get '/me' => needs login => sub {
  status_200();
};

post '/user/me/settings' => needs login => sub {
  my $user_id  = session->read('user_id');
  my $settings = body_parameters->as_hashref;

  return status_400("No settings specified or invalid JSON given")
    unless $settings;

  my $user = lookup_user( schema, $user_id );
  my $status = set_user_settings( schema, $user, $settings );

  if ($status) {
    return status_200( { status => "updated settings for user" } );
  }
  else {
    return status_500(
      { error => "error occured determining settings for user" } );
  }
};

get '/user/me/settings' => needs login => sub {
  my $user_id   = session->read('user_id');
  my $keys_only = param 'keys_only';

  my $user = lookup_user( schema, $user_id );
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

post '/user/me/settings/:key' => needs login => sub {
  my $setting_key = param 'key';
  my $user_id     = session->read('user_id');
  my $setting     = body_parameters->as_hashref;

  my $setting_value = $setting->{$setting_key};

  return status_400(
    "Setting key in request body must match name in the URL ('$setting_key')")
    unless defined $setting_value;

  my $user = lookup_user( schema, $user_id );
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

get '/user/me/settings/:key' => needs login => sub {
  my $setting_key = param 'key';
  my $user_id     = session->read('user_id');

  my $user = lookup_user( schema, $user_id );
  my $setting = get_user_setting( schema, $user, $setting_key );

  if ($setting) {
    return status_200($setting);
  }
  else {
    return status_404( { error => "No such setting '$setting_key'" } );
  }
};

del '/user/me/settings/:key' => needs login => sub {
  my $setting_key = param 'key';
  my $user_id     = session->read('user_id');

  my $user = lookup_user( schema, $user_id );
  my $deleted = delete_user_setting( schema, $user, $setting_key );

  if ($deleted) {
    return status_200(
      { "status" => "deleted setting '$setting_key' for user" } );
  }
  else {
    return status_404("setting '$setting_key' does not exist");
  }

};
1;
