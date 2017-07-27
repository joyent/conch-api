package Conch::Control::Problem;

use strict;
use Log::Report;
use List::Compare;
use Dancer2::Plugin::Passphrase;
use Conch::Control::User;
use Conch::Control::Datacenter;
use Conch::Control::Device;
use Conch::Control::Rack;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( get_problems );

# The report / validation format is not normalized yet, so this is going to be
# a giant mess. Sorry. -- bdha
sub get_problems {
  my ($schema, $user_name) = @_;

  my $problems   = {};
  my $rack_roles = rack_roles($schema);
  my $criteria   = get_validation_criteria($schema);

  my @failing_user_devices = get_failing_user_devices($schema, $user_name);

  foreach my $device (@failing_user_devices) {
    my $device_info     = device_info($schema, $device);
    my $device_location = device_location($schema, $device);

    my $rack_info       = get_rack($schema, $device_location->rack_id);
    my $datacenter      = get_datacenter_room($schema, $rack_info->datacenter_room_id);
    my $report_id       = newest_report($schema, $device);

    $problems->{$device}{health}     = $device_info->health;
    $problems->{$device}{report_id}  = $report_id;

    $problems->{$device}{rack}{id}   = $device_location->rack_id || undef;
    $problems->{$device}{rack}{unit} = $device_location->rack_unit || undef;
    $problems->{$device}{rack}{name} = $rack_info->name || undef;
    $problems->{$device}{rack}{role} = $rack_info->role->name || undef;

    $problems->{$device}{datacenter}{id}   = $datacenter->id;
    $problems->{$device}{datacenter}{name} = $datacenter->az;

    my @validation_report = device_validation_report($schema, $report_id);

    my @problems;
    foreach my $v (@validation_report) {
      my $fail = {};
      if ($v->{status} eq 0) {
        $fail->{criteria}{id}           = $v->{criteria_id} || undef;
        $fail->{criteria}{component}    = $criteria->{ $v->{criteria_id} }{component} || undef;
        $fail->{criteria}{condition}    = $criteria->{ $v->{criteria_id} }{condition} || undef;
        $fail->{criteria}{min}          = $criteria->{ $v->{criteria_id} }{min} || undef;
        $fail->{criteria}{warn}         = $criteria->{ $v->{criteria_id} }{warn} || undef;
        $fail->{criteria}{crit}         = $criteria->{ $v->{criteria_id} }{crit} || undef;

        $fail->{component_id}   = $v->{component_id} || undef;
        $fail->{component_name} = $v->{component_name} || undef;
        $fail->{component_type} = $v->{component_type} || undef;
        $fail->{log}            = $v->{log} || undef;
        $fail->{metric}         = $v->{metric} || undef;
        push @problems,$fail;
      }
    }
    $problems->{$device}{problems} = \@problems;
  }

  return $problems;
}

sub newest_report {
  my ($schema, $device) = @_;

  # Get the most recent entry in device_report.
  my $report = $schema->resultset('DeviceReport')->search(
    { device_id => $device },
    { order_by => { -desc => 'created' },
      columns => qw/id created/ }
  )->first;

  return $report->id;
}

sub get_failing_user_devices {
  my ($schema, $user_name) = @_;

  my @user_devices = devices_for_user($schema, $user_name);

  #  If at some point we care about time-bounding when we've seen failures,
  #  add this:
  #  last_seen => \' > NOW() - INTERVAL \'2 minutes\'',
  my @failing_rs = $schema->resultset('Device')->search({
    health => "FAIL",
  });

  my @failing_devices;
  foreach my $f (@failing_rs) {
    push @failing_devices, $f->id;
  }

  my $lc = List::Compare->new(\@user_devices,\@failing_devices);

  my @failing_user_devices = $lc->get_intersection;

  return @failing_user_devices;
}

1;
