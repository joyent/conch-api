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
  validate_user_id lookup_user authenticate generate_random_password
  hash_password reset_user_password
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
  my $user = $schema->resultset('UserAccount')->find( { name => $name } );

  $user or $log->warning("user name '$name' not found") and return undef;

  if ( passphrase($password)->matches( $user->password_hash ) ) {
    return $user;
  }
  return undef;
}

sub generate_random_password {
  my $length = shift || 8;

  my $password = passphrase->generate_random( { length => $length } );
  my $password_hash = hash_password($password);
  return {
    password      => $password,
    password_hash => $password_hash
  };
}

sub hash_password {
  my $password = shift;
  return passphrase($password)->generate->rfc2307;
}

sub reset_user_password {
  my ( $schema, $email, $emailer ) = @_;

  my $user = $schema->resultset('UserAccount')->find( { email => $email } );
  return unless $user;

  my $pw = generate_random_password();
  $user->password_hash( $pw->{password_hash} );
  $user->update;
  $emailer->(
    {
      name     => $user->name,
      email    => $email,
      password => $pw->{password}
    }
  );

  1;
}

1;
