package Conch::Control::Device;

use strict;
use Log::Report;
use Log::Report::DBIC::Profiler;
use Dancer2::Plugin::Passphrase;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( devices_for_user );

sub devices_for_user {
  my ($schema, $user_name) = @_;

  my @user_devices;

  foreach my $device ($schema->resultset('UserDeviceAccess')->
                      search({}, { bind => [$user_name] })->all) {
    push @user_devices,$device->id;
  }

  return @user_devices;

};


1;
