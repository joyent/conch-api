package Conch::Control::DeviceReport;

use strict;
use Storable 'dclone';
use Log::Any '$log';
use Conch::Data::Report::Server;
use Conch::Data::Report::Switch;
use Conch::Control::Device::Environment;
use Conch::Control::Relay;
use JSON::XS;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( parse_device_report record_device_report );

# Parse a report object from a HashRef and report all validation errors
# Returns a list where the first element may be the parsed log and the second
# may be validation errors, but not both.
sub parse_device_report {
  my $input      = shift;
  my $aux_report = dclone($input);

  my $report;
  if ( $input->{device_type} eq "switch" ) {
    eval { $report = Conch::Data::Report::Switch->new($input); };
  }
  else {
    eval { $report = Conch::Data::Report::Server->new($input); };
  }

  if ($@) {
    my $errs = join( "; ", map { $_->message } $@->errors );
    $log->warning("Error validating device report: $errs");
    return ( undef, $errs );
  }
  else {
    for my $attr ( keys %{ $report->pack() } ) {
      delete $aux_report->{$attr};
    }
    if ( %{$aux_report} ) {
      $report->{aux} = $aux_report;
    }
    return ($report);
  }
}

sub add_reboot_count {
  my $device = shift;

  my $reboot_count =
    $device->device_settings->find_or_new( { name => 'reboot_count' } );
  $reboot_count->updated( \'NOW()' );

  if ( $reboot_count->in_storage ) {
    $reboot_count->value( 1 + $reboot_count->value );
    $reboot_count->update;
  }
  else {
    $reboot_count->value(0);
    $reboot_count->insert;
  }
}

# Returns a Device for processing in the validation steps
sub record_device_report {
  my ( $schema, $dr ) = @_;
  my $hw = $schema->resultset('HardwareProduct')->find(
    {
      name => $dr->{product_name}
    }
  );
  $hw or die $log->critical("Product $dr->{product_name} not found");

  my $hw_profile = $hw->hardware_product_profile;
  $hw_profile
    or die $log->criticalf(
    "Hardware product '%s' exists but does not have a hardware profile",
    $hw->name );

  $log->info("Ready to record report for Device $dr->{serial_number}");

  my $device;
  my $device_report;

  $schema->txn_do(
    sub {

      my $prev_device =
        $schema->resultset('Device')->find( { id => $dr->{serial_number} } );

      my $prev_uptime = $prev_device && $prev_device->uptime_since;

      $device = $schema->resultset('Device')->update_or_create(
        {
          id               => $dr->{serial_number},
          system_uuid      => $dr->{system_uuid},
          hardware_product => $hw->id,
          state            => $dr->{state},
          health           => "UNKNOWN",
          last_seen        => \'NOW()',
          uptime_since     => $dr->{uptime_since} || $prev_uptime
        }
      );
      my $device_id = $device->id;
      $log->info("Created Device $device_id");

      # Add a reboot count if there's not a previous uptime but one in this
      # report (i.e. first uptime reported), or if the previous uptime date is
      # less than the the current one (i.e. there has been a reboot)
      add_reboot_count($device)
        if ( !$prev_uptime && $device->{uptime_since} )
        || $device->{uptime_since} && $prev_uptime < $device->{uptime_since};

      device_relay_connect( $schema, $device_id, $dr->{relay}{serial} )
        if $dr->{relay};

      # Stores the JSON representation of device report as serialized
      # by MooseX::Storage
      $device_report = $schema->resultset('DeviceReport')->create(
        {
          device_id => $device_id,
          report    => $dr->freeze()
        }
      );

      my $nics_num = $dr->nics_count;

      my $device_specs = $schema->resultset('DeviceSpec')->update_or_create(
        {
          device_id     => $device_id,
          product_id    => $hw_profile->id,
          bios_firmware => $dr->{bios_version},
          cpu_num       => $dr->{processor}->{count},
          cpu_type      => $dr->{processor}->{type},
          nics_num      => $nics_num,
          dimms_num     => $dr->{memory}->{count},
          ram_total     => $dr->{memory}->{total},
        }
      );

      $log->info("Created Device Spec for Device $device_id");

      $schema->resultset('DeviceEnvironment')->update_or_create(
        {
          device_id    => $device->id,
          cpu0_temp    => $dr->{temp}->{cpu0},
          cpu1_temp    => $dr->{temp}->{cpu1},
          inlet_temp   => $dr->{temp}->{inlet},
          exhaust_temp => $dr->{temp}->{exhaust},
        }
      ) if $dr->{temp};

      $dr->{temp}
        and $log->info("Recorded environment for Device $device_id");

      my @device_disks = $schema->resultset('DeviceDisk')->search(
        {
          device_id   => $device_id,
          deactivated => { '=', undef }
        }
      )->all;

      # Keep track of which disk serials have been previously recorded in the
      # DB but are no longer being reported due to a disk swap, etc.
      my %inactive_serials = map { $_->serial_number => 1 } @device_disks;

      foreach my $disk ( keys %{ $dr->{disks} } ) {
        $log->trace("Device $device_id: Recording disk: $disk");

        if ( $inactive_serials{$disk} ) {
          $inactive_serials{$disk} = 0;
        }

        my $disk_rs = $schema->resultset('DeviceDisk')->update_or_create(
          {
            device_id     => $device->id,
            serial_number => $disk,
            slot          => $dr->{disks}->{$disk}->{slot},
            hba           => $dr->{disks}->{$disk}->{hba},
            enclosure     => $dr->{disks}->{$disk}->{enclosure},
            vendor        => $dr->{disks}->{$disk}->{vendor},
            health        => $dr->{disks}->{$disk}->{health},
            size          => $dr->{disks}->{$disk}->{size},
            model         => $dr->{disks}->{$disk}->{model},
            temp          => $dr->{disks}->{$disk}->{temp},
            drive_type    => $dr->{disks}->{$disk}->{drive_type},
            transport     => $dr->{disks}->{$disk}->{transport},
            firmware      => $dr->{disks}->{$disk}->{firmware},
            deactivated   => undef,
            updated     => \'NOW()'
          }
        );
      }

      my @inactive_serials =
        grep { $inactive_serials{$_} } keys %inactive_serials;

      # Deactivate all disks that were previously recorded but are no longer
      # reported in the device report
      if ( scalar @inactive_serials ) {
        $schema->resultset('DeviceDisk')
          ->search_rs( { serial_number => { -in => \@inactive_serials } } )
          ->update( { deactivated => \'NOW()', updated => \'NOW()' } );
      }

      $dr->{disks}
        and $log->info("Recorded disk info for Device $device_id");

      my @device_nics = $schema->resultset('DeviceNic')->search(
        {
          device_id   => $device_id,
          deactivated => { '=', undef }
        }
      )->all;

      my %inactive_macs = map { uc( $_->mac ) => 1 } @device_nics;

      foreach my $nic ( keys %{ $dr->{interfaces} } ) {

        my $mac = uc( $dr->{interfaces}->{$nic}->{mac} );

        $log->trace( "Device $device_id: Recording NIC: $mac" );

        if ( $inactive_macs{$mac} ) {
          $inactive_macs{$mac} = 0;
        }

        my $nic_rs = $schema->resultset('DeviceNic')->update_or_create(
          {
            mac          => $mac,
            device_id    => $device->id,
            iface_name   => $nic,
            iface_type   => $dr->{interfaces}->{$nic}->{product},
            iface_vendor => $dr->{interfaces}->{$nic}->{vendor},
            iface_driver => '',
            updated      => \'NOW()',
            deactivated  => undef
          }
        );

        my $nic_state = $schema->resultset('DeviceNicState')->update_or_create(
          {
            mac     => $mac,
            state   => $dr->{interfaces}->{$nic}->{state},
            ipaddr  => $dr->{interfaces}->{$nic}->{ipaddr},
            mtu     => $dr->{interfaces}->{$nic}->{mtu},
            updated => \'NOW()'
          }
        );

        my $nic_peers = $schema->resultset('DeviceNeighbor')->update_or_create(
          {
            mac         => $mac,
            raw_text    => $dr->{interfaces}->{$nic}->{peer_text},
            peer_switch => $dr->{interfaces}->{$nic}->{peer_switch},
            peer_port   => $dr->{interfaces}->{$nic}->{peer_port},
            peer_mac    => $dr->{interfaces}->{$nic}->{peer_mac},
            updated     => \'NOW()'
          }
        );
      }

      my @inactive_macs =
        grep { $inactive_macs{$_} } keys %inactive_macs;

      # Deactivate all nics that were previously recorded but are no longer
      # reported in the device report
      if ( scalar @inactive_macs ) {
        $schema->resultset('DeviceNic')
          ->search_rs( { mac => { -in => \@inactive_macs } } )
          ->update( { deactivated => \'NOW()', updated => \'NOW()' } );
      }

    }
  );
  return ( $device, $device_report->id );
}

1;
