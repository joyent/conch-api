package Conch::Control::User::Setting;

use strict;
use Log::Any '$log';
use JSON::XS;

use Data::Printer;

use Exporter 'import';
our @EXPORT =
  qw( set_user_settings set_user_setting get_user_settings get_user_setting delete_user_setting );

# Allow JSON values to be en/decoded
my $json = JSON::XS->new->allow_nonref;

sub set_user_settings {
  my ( $schema, $user, $settings ) = @_;

  $schema->txn_do(
    sub {
      for my $setting_key ( keys %{$settings} ) {
        my $value = $settings->{$setting_key};
        set_user_setting( $schema, $user, $setting_key, $value );
      }
    }
  );

  return 1;
}

sub set_user_setting {
  my ( $schema, $user, $setting_key, $setting_value ) = @_;

  my $prev_setting =
    $user->user_settings->find(
    { name => $setting_key, deactivated => undef } );

  $prev_setting->update( { deactivated => \'NOW()' } )
    if $prev_setting;

  $user->user_settings->create(
    {
      user_id => $user->id,
      name    => $setting_key,
      value   => $json->encode($setting_value)
    }
  );

  return 1;
}

sub get_user_settings {
  my ( $schema, $user ) = @_;

  my @user_settings = $user->user_settings->search(
    {
      deactivated => undef
    }
  );

  my $res = {};
  for my $setting (@user_settings) {
    $res->{ $setting->name } = $json->decode( $setting->value );
  }
  return $res;
}

sub get_user_setting {
  my ( $schema, $user, $setting_key ) = @_;

  my $setting = $user->user_settings->find(
    {
      name        => $setting_key,
      deactivated => undef
    }
  );
  return { $setting_key => $json->decode( $setting->value ) } if $setting;
}

sub delete_user_setting {
  my ( $schema, $user, $setting_key ) = @_;

  my $setting = $user->user_settings->find(
    {
      name        => $setting_key,
      deactivated => undef
    }
  );
  return 0 unless $setting;
  $setting->update( { deactivated => \'NOW()' } );
  1;
}

1;
