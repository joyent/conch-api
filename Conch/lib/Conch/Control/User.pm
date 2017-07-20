package Conch::Control::User;

use strict;
use Log::Report;
use Dancer2 appname => 'Conch';
use Dancer2::Plugin::Passphrase;

use Conch::Data::UserLogin;
use Conch::Control::Device::Environment;

use Exporter 'import';
our @EXPORT = qw( lookup_user_by_name authenticate create_integrator_user create_admin_passphrase );

sub lookup_user_by_name {
  my ($schema, $name) = @_;
  return $schema->resultset('UserAccount')->search({
    name => $name
  })->single;
};

sub authenticate {
  my ($schema, $name, $password) = @_;
  my $user = lookup_user_by_name($schema, $name);
  $user or error "user name not found";

  return passphrase($password)->matches($user->password_hash);
};


sub create_integrator_user {
  my ($schema, $name) = @_;
  my $password = create_integrator_password();
  $schema->resultset('UserAccount')->create({
      name => $name,
      password_hash => passphrase($password)->generate->rfc2307,
  });
  return { name => $name, password => $password };
};

sub create_integrator_password {
  # Password are 8 digits
  return passphrase->generate_random({
      length => 8,
      charset => ['0'..'9']
  });
};

# Useful from a one-liner if a new password is needed
# > carton exec perl -Ilib -mConch::Control::User -e \
#      'my $pw = Conch::Control::User::create_admin_passphrase(); \
#       print $pw->{password} . "\n" . $pw->{password_hash};'
sub create_admin_passphrase {
  # 24 character long passwords
  my $password = passphrase->generate_random({
      length => 24
  });
  my $password_hash = passphrase($password)->generate->rfc2307;
  return {
    password => $password,
    password_hash => $password_hash
  };
};

1;
