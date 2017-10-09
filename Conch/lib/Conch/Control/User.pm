package Conch::Control::User;

use strict;
use Log::Any '$log';

# required for 'passphrase'. Dumb.
use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Passphrase;
use Data::Printer;

use Exporter 'import';
our @EXPORT =
  qw( lookup_user_by_name user_id_by_name authenticate create_integrator_user create_admin_passphrase );

sub lookup_user_by_name {
  my ( $schema, $name ) = @_;
  return $schema->resultset('UserAccount')->find(
    {
      name => $name
    }
  );
}

sub user_id_by_name {
  my ( $schema, $name ) = @_;
  return $schema->resultset('UserAccount')
    ->find( { name => $name }, { columns => 'id' } )->id;
}

sub authenticate {
  my ( $schema, $name, $password ) = @_;
  my $user = lookup_user_by_name( $schema, $name );
  $user or $log->warning("user name '$name' not found") and return 0;

  return passphrase($password)->matches( $user->password_hash );
}

sub create_integrator_user {
  my ( $schema, $name ) = @_;
  my $password = create_integrator_password();
  $schema->resultset('UserAccount')->create(
    {
      name          => $name,
      password_hash => passphrase($password)->generate->rfc2307,
    }
  );
  return { name => $name, password => $password };
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
