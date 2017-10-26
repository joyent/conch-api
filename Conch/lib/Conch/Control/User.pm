package Conch::Control::User;

use strict;
use warnings;
use Log::Any '$log';

# required for 'passphrase'. Dumb.
use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Passphrase;
use Data::Printer;

use Exporter 'import';
our @EXPORT = qw(
  validate_user_id lookup_user authenticate create_admin_passphrase
  create_integrator_password hash_password
);

sub validate_user_id {
  my ( $schema, $user_id ) = @_;
  return $schema->resultset('UserAccount')->find(
    {
      id => $user_id
    },
    { columns => 'id' }
  );
}

sub lookup_user {
  my ( $schema, $user_id ) = @_;
  return $schema->resultset('UserAccount')->find(
    {
      id => $user_id
    }
  );
}

sub authenticate {
  my ( $schema, $name, $password ) = @_;
  my $user = $schema->resultset('UserAccount')->find(
    {
      name => $name
    }
  );

  $user or $log->warning("user name '$name' not found") and return undef;

  if ( passphrase($password)->matches( $user->password_hash ) ) {
    return $user;
  }
  return undef;
}

sub hash_password {
  my $password = shift;
  return passphrase($password)->generate->rfc2307;
}

sub create_integrator_password {

  # Password are 8 digits
  return passphrase->generate_random(
    {
      length  => 8,
      charset => [ '0' .. '9' ]
    }
  );
}

# Useful from a one-liner if a new password is needed
# > carton exec perl -Ilib -mConch::Control::User -e \
#      'my $pw = Conch::Control::User::create_admin_passphrase(); \
#       print $pw->{password} . "\n" . $pw->{password_hash};'
sub create_admin_passphrase {

  # 24 character long passwords
  my $password = passphrase->generate_random(
    {
      length => 24
    }
  );
  my $password_hash = passphrase($password)->generate->rfc2307;
  return {
    password      => $password,
    password_hash => $password_hash
  };
}

1;
