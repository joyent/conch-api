package Conch::Model::DeviceReport;
use Mojo::Base -base, -signatures;

use Attempt qw(try fail success attempt when_defined);

has 'pg';
has 'log';

sub latest_device_report ( $self, $device_id ) {
  attempt $self->pg->db->query(
    q{
      SELECT me.id, me.device_id, me.report, me.created
      FROM device_report me
      WHERE me.id IN (
        SELECT dr.id FROM device_report dr
        WHERE dr.device_id = ?
        ORDER BY dr.created DESC
        LIMIT 1
      )
    }, $device_id
  )->expand->hash;
}

sub validation_results ( $self, $report_id ) {
  $self->pg->db->select( 'device_validate', undef, { report_id => $report_id } )
    ->expand->hashes->to_array;
}

# Returns a Device for processing in the validation steps
sub record_device_report ( $self, $dr ) {
  my $db = $self->pg->db;
  my $hw = attempt $db->select( 'hardware_product', undef,
    { name => $dr->{product_name} } )->hash;
  return fail("Product $dr->{product_name} not found")
    if $hw->is_fail;

  my $hw_profile = $db->select( 'hardware_product_profile', undef,
    { product_id => $hw->{id} } );

  $self->log->info("Ready to record report for Device $dr->{serial_number}");

  return try {
    my $device_report_id;
    my $tx = $db->begin;

    my $maybe_device = $self->device->lookup->( $dr->{serial_number} );

    my $device_id;
    if ( $maybe_device->is_fail ) {
      $device_id = $self->device->create(
        {
          id               => $dr->{serial_number},
          system_uuid      => $dr->{system_uuid},
          hardware_product => $hw->{id},
          state            => $dr->{state},
          health           => "UNKNOWN",
          last_seen        => 'NOW()',
          uptime_since     => $dr->{uptime_since}
        }
      );
      $self->log->info("Created Device $device_id");
      _add_reboot_count( $db, $device_id );
    }
    else {
      $device_id = $maybe_device->value->id;
      $self->device->mark_uptime_last_seen( $dr->{uptime_since} );

      _add_reboot_count( $db, $device_id )
        if $dr - $maybe_device->value->uptime_since > $dr->{uptime_since};
    }

    _device_relay_connect( $db, $device_id, $dr->{relay}{serial} )
      if $dr->{relay};

    # Stores the JSON representation of device report as serialized
    # by MooseX::Storage
    $device_report_id = $db->insert(
      'device_report',
      {
        device_id => $device_id,
        report    => $dr->freeze()
      },
      { returning => ['id'] }
    );

    my $nics_num = $dr->{nics_count};
    $db->query(
      q{
      INSERT INTO device_spec
        ( device_id, product_id, bios_firmware, cpu_num, cpu_type, nics_num,
          dimms_num, ram_total )
      VALUES
        (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (device_id) DO UPDATE
      SET product_id = excluded.product_id,
        bios_firmware = excluded.bios_firmware,
        cpu_num = excluded.cpu_num,
        cpu_type = excluded.cpu_type,
        nics_num = excluded.nics_num,
        dimms_num = excluded.dimms_num,
        ram_total = excluded.ram_total
      },
      $device_id,
      $hw_profile->{id},
      $dr->{bios_version},
      $dr->{processor}->{count},
      $dr->{processor}->{type},
      $nics_num,
      $dr->{memory}->{count},
      $dr->{memory}->{total}
    );

    $self->log->info("Created Device Spec for Device $device_id");

    $db->query(
      q{
      INSERT INTO device_environment
        (device_id, cpu0_temp, cpu1_temp, inlet_temp, exhaust_temp)
      VALUES
        (?, ?, ?, ?, ?)
      ON CONFLICT (device_id) DO UPDATE
      SET cpu0_temp = excluded.cpu0_temp,
          cpu1_temp = excluded.cpu1_temp,
          inlet_temp = excluded.inlet_temp,
          exhaust_temp = excluded.exhaust_temp
      },
      $device_id,
      $dr->{temp}->{cpu0},
      $dr->{temp}->{cpu1},
      $dr->{temp}->{inlet},
      $dr->{temp}->{exhaust},
    ) if $dr->{temp};

    $dr->{temp}
      and $self->log->info("Recorded environment for Device $device_id");

    _record_device_disks( $db, $device_id, $dr );
    $self->log->info("Recorded disk info for Device $device_id");

    _record_device_nics( $db, $device_id, $dr );
    $self->log->info("Recorded NIC info for Device $device_id");

    $tx->commit;
    return $device_report_id;
  };
}

# Add or update the reboot_count setting
sub _add_reboot_count ( $db, $device_id ) {
  $db->query(
    q{
      INSERT INTO device_settings
        (device_id, name, value)
      VALUES
        (?, 'reboot_count', '0')
      ON CONFLICT (device_id, name) WHERE deactivated IS NULL DO UPDATE
      SET value = (device_settings.value::int + 1),
          updated = NOW()
    }, $device_id
  );
}

sub _device_relay_connect ( $db, $device_id, $relay_id ) {

  # 'first_seen' column will only be written on create. It should remain
  # untouched on updates
  $db->query(
    q{
      INSERT INTO device_relay_connection
        ( device_id, relay_id, last_seen )
      VALUES ( ?, ?, ? )
      ON CONFLICT (device_id) DO UPDATE
      SET device_id = excluded.device_id,
          relay_id = excluded.relay_id,
          last_seen = excluded.last_seen
    },
    $device_id,
    $relay_id,
    'NOW()'
  );
}

sub _record_device_nics ( $db, $device_id, $dr ) {
  my $device_nics = $db->select(
    'device_nic',
    undef,
    {
      device_id   => $device_id,
      deactivated => undef
    }
  )->hashes->to_array;

  my %inactive_macs = map { uc( $_->{mac} ) => 1 } @$device_nics;

  foreach my $nic ( keys %{ $dr->{interfaces} } ) {

    my $mac = uc( $dr->{interfaces}->{$nic}->{mac} );

    if ( $inactive_macs{$mac} ) {
      $inactive_macs{$mac} = 0;
    }

    $db->query(
      q{
      INSERT INTO device_nic
        (mac, device_id, iface_name, iface_type, iface_vendor,
        iface_driver, updated, deactivated)
      VALUES
        (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (device_id) DO UPDATE
      SET mac = excluded.mac,
          device_id = excluded.device_id,
          iface_name = excluded.iface_name,
          iface_type = excluded.iface_type,
          iface_vendor = excluded.iface_vendor,
          iface_driver = excluded.iface_driver,
          updated = excluded.updated,
          deactivated = excluded.deactivated
      }, $mac,
      $device_id,
      $nic,
      $dr->{interfaces}->{$nic}->{product},
      $dr->{interfaces}->{$nic}->{vendor},
      '',
      'NOW()',
      undef
    );

    $db->query(
      q{
      INSERT INTO device_nic_state
        ( mac, state, ipaddr, mtu, updated )
      VALUES
        (?, ?, ?, ?, ?)
      ON CONFLICT (mac) DO UPDATE
      SET mac = excluded.mac,
          state = excluded.state,
          ipaddr = excluded.ipaddr,
          mtu = excluded.mtu,
          updated = excluded.updated
      }, $mac,
      $dr->{interfaces}->{$nic}->{state},
      $dr->{interfaces}->{$nic}->{ipaddr},
      $dr->{interfaces}->{$nic}->{mtu},
      'NOW()'
    );

    $db->query(
      q{
      INSERT INTO device_neighbor
        ( mac, raw_text, peer_switch, peer_port, peer_mac, updated )
      VALUES
        ( ?, ?, ?, ?, ?, ? )
      ON CONFLICT (mac) DO UPDATE
      SET mac = excluded.mac,
          raw_text = excluded.raw_text,
          peer_switch = excluded.peer_switch,
          peer_port = excluded.peer_port,
          peer_mac = excluded.peer_mac,
          updated = excluded.updated
      },
      $mac,
      $dr->{interfaces}->{$nic}->{peer_text},
      $dr->{interfaces}->{$nic}->{peer_switch},
      $dr->{interfaces}->{$nic}->{peer_port},
      $dr->{interfaces}->{$nic}->{peer_mac},
      'NOW()'
    );
  }

  my @inactive_macs =
    grep { $inactive_macs{$_} } keys %inactive_macs;

  # Deactivate all nics that were previously recorded but are no longer
  # reported in the device report
  if ( scalar @inactive_macs ) {
    $db->update(
      'device_nic',
      { mac => { -in => \@inactive_macs } },
      { deactivated => 'NOW()', updated => 'NOW()' }
    );
  }
}

sub _record_device_disks ( $db, $device_id, $dr ) {
  my $device_disks = $db->select(
    'device_disk',
    undef,
    {
      device_id   => $device_id,
      deactivated => undef
    }
  )->hashes->to_array;

  # Keep track of which disk serials have been previously recorded in the
  # DB but are no longer being reported due to a disk swap, etc.
  my %inactive_serials = map { $_->{serial_number} => 1 } @$device_disks;

  foreach my $disk ( keys %{ $dr->{disks} } ) {
    if ( $inactive_serials{$disk} ) {
      $inactive_serials{$disk} = 0;
    }

    $db->query(
      q{
      INSERT INTO device_disk
        ( device_id, serial_number, slot, hba, enclosure, vendor, health,
          size, model, temp, drive_type, transport, firmware, deactivated,
          updated )
      VALUES
        ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )
      ON CONFLICT (device_id) DO UPDATE
      SET device_id = excluded.device_id,
          serial_number = excluded.serial_number,
          slot = excluded.slot,
          hba = excluded.hba,
          enclosure = excluded.enclosure,
          vendor = excluded.vendor,
          health = excluded.health,
          size = excluded.size,
          model = excluded.model,
          temp = excluded.temp,
          drive_type = excluded.drive_type,
          transport = excluded.transport,
          firmware = excluded.firmware,
          deactivated = excluded.deactivated,
          updated  = excluded.updated
      },
      $device_id,
      $disk,
      $dr->{disks}->{$disk}->{slot},
      $dr->{disks}->{$disk}->{hba},
      $dr->{disks}->{$disk}->{enclosure},
      $dr->{disks}->{$disk}->{vendor},
      $dr->{disks}->{$disk}->{health},
      $dr->{disks}->{$disk}->{size},
      $dr->{disks}->{$disk}->{model},
      $dr->{disks}->{$disk}->{temp},
      $dr->{disks}->{$disk}->{drive_type},
      $dr->{disks}->{$disk}->{transport},
      $dr->{disks}->{$disk}->{firmware},
      undef,
      'NOW()'
    );
  }

  my @inactive_serials =
    grep { $inactive_serials{$_} } keys %inactive_serials;

  # Deactivate all disks that were previously recorded but are no longer
  # reported in the device report
  if ( scalar @inactive_serials ) {
    $db->update(
      'device_disk',
      { serial_number => { -in => \@inactive_serials } },
      { deactivated => 'NOW()', updated => 'NOW()' }
    );
  }
}

1;
