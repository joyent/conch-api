package Conch::Route::Collect;

use Dancer2 appname => 'Conch';
use Hash::MultiValue;
use Dancer2::Plugin::DBIC;
set serializer => 'JSON';


prefix '/api' => sub {

  post '/device' => sub {
    my $body = body_parameters;
    my $product_name = $body->{product_name};

    my $hw_rs = resultset('HardwareProduct')->search({
      name => $product_name
    });

    my $hw = $hw_rs->first;
    my $hw_profile_rs = resultset('HardwareProductProfile')->search({
      product_id       => $hw->id
    });

    my $hw_profile = $hw_profile_rs->first;

    debug("Serial Number: $body->{serial_number}: Recording device");

    my $device_rs = resultset('Device')->update_or_create({
      id               => $body->{serial_number},
      system_uuid      => $body->{system_uuid},
      hardware_product => $hw->id,
      state            => $body->{state},
      health           => "UNKNOWN",
      last_seen        => \'NOW()',
    });

    my %interfaces = %{$body->{interfaces}};
    my $nics_num = keys %interfaces;

    my $device_id = $device_rs->id;

    debug("Device $device_id: Recording device specs");

    my $device_specs = resultset('DeviceSpec')->update_or_create({
      device_id       => $device_rs->id,
      product_id      => $hw_profile->id,
      bios_firmware   => $body->{bios_version},
      cpu_num         => $body->{processor}->{count},
      cpu_type        => $body->{processor}->{type},
      nics_num        => $nics_num,
      dimms_num       => $body->{memory}->{count},
      ram_total       => $body->{memory}->{total},
    });

    debug("Device $device_id: Recording environmentals");

    my $device_env = resultset('DeviceEnvironment')->update_or_create({
        device_id       => $device_rs->id,
        cpu0_temp       => $body->{temp}->{cpu0},
        cpu1_temp       => $body->{temp}->{cpu1},
        inlet_temp      => $body->{temp}->{inlet},
        exhaust_temp    => $body->{temp}->{exhaust},
      });


    debug("Device $device_id: Recording disks");

    # XXX If a disk vanishes/replaces, we need to mark it deactivated here.
    foreach my $disk (keys %{$body->{disks}}) {
      debug("Device $device_id: Recording disk: $disk");

      my $disk_rs = resultset('DeviceDisk')->update_or_create({
        device_id       => $device_rs->id,
        serial_number   => $disk,
        slot            => $body->{disks}->{$disk}->{slot},
        hba             => $body->{disks}->{$disk}->{hba},
        vendor          => $body->{disks}->{$disk}->{vendor},
        health          => $body->{disks}->{$disk}->{health},
        size            => $body->{disks}->{$disk}->{size},
        model           => $body->{disks}->{$disk}->{model},
        temp            => $body->{disks}->{$disk}->{temp},
        drive_type      => $body->{disks}->{$disk}->{drive_type},
        transport       => $body->{disks}->{$disk}->{transport},
        firmware        => $body->{disks}->{$disk}->{firmware},
      });
    }

    foreach my $nic (keys %{$body->{interfaces}}) {

      debug("Device $device_id: Recording NIC: $body->{interfaces}->{$nic}->{mac}");

      my $nic_rs = resultset('DeviceNic')->update_or_create({
          mac           => $body->{interfaces}->{$nic}->{mac},
          device_id     => $device_rs->id,
          iface_name    => $nic,
          iface_type    => $body->{interfaces}->{$nic}->{product},
          iface_vendor  => $body->{interfaces}->{$nic}->{vendor},
          iface_driver  => "",
        });

      my $nic_state = resultset('DeviceNicState')->update_or_create({
          mac           => $body->{interfaces}->{$nic}->{mac},
          state         => $body->{interfaces}->{$nic}->{state},
          ipaddr        => $body->{interfaces}->{$nic}->{ipaddr},
          mtu           => $body->{interfaces}->{$nic}->{mtu},
        });

      my $nic_peers = resultset('DeviceNeighbor')->update_or_create({
          mac           => $body->{interfaces}->{$nic}->{mac},
          raw_text      => $body->{interfaces}->{$nic}->{peer_text},
          peer_switch   => $body->{interfaces}->{$nic}->{peer_switch},
          peer_port     => $body->{interfaces}->{$nic}->{peer_port},
        });
    }

    return { count => $hw_rs->count };
  };

};

1;
