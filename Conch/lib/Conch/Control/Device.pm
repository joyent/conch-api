package Conch::Control::Device;

use strict;
use Log::Report;
use Log::Report::DBIC::Profiler;
use Dancer2::Plugin::Passphrase;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( devices_for_user device_inventory );

sub devices_for_user {
  my ($schema, $user_name) = @_;

  my @user_devices;

  foreach my $device ($schema->resultset('UserDeviceAccess')->
                      search({}, { bind => [$user_name] })->all) {
    push @user_devices,$device->id;
  }

  return @user_devices;

};

sub device_inventory {
  my ($schema, $device_id) = @_;

  # Get the most recent entry in device_report.
  my $report = $schema->resultset('DeviceReport')->search(
    { device_id => $device_id },
    { order_by => { -desc => 'created' } }
  )->first;

  return Dancer2::Serializer::JSON::from_json($report->report);
}

1;
