package Conch::Control::Device::Inventory;

use strict;
use Log::Report;
use JSON::XS;
use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( validate_system validate_nics_num validate_bios_firmware
                  validate_disks
                );


sub validate_system {
  my ($schema, $device, $report_id) = @_;

  $device or fault "device undefined";

  my $device_id = $device->id;
  trace("$device_id: report $report_id: Validating system inventory");

  my $device_spec = $device->device_spec;
  my $hw_product  = $device->hardware_product;
  my $hw_profile  = $hw_product->hardware_product_profile;

  # Ensure we have correct number of CPUs
  my $cpu_num_status;
  my $cpu_num_log = "Has = " . $device_spec->cpu_num .", Want = " . $hw_profile->cpu_num;

  if ( $device_spec->cpu_num != $hw_profile->cpu_num ) {
    $cpu_num_status = 0;
    mistake("$device_id: report $report_id: CRITICAL: Incorrect CPU count: $cpu_num_log");
  } else {
    $cpu_num_status = 1;
    trace ("$device_id: report $report_id: OK: Correct CPU count: $cpu_num_log");
  }

  $schema->resultset('DeviceValidate')->create({
    device_id       => $device_id,
    report_id       => $report_id,
    validation      => encode_json({
      component_type  => "CPU",
      component_name  => "cpu_count",
      metric          => $device_spec->cpu_num,
      log             => $cpu_num_log,
      status          => $cpu_num_status
    })
  });

  # Ensure we have correct number of DIMMs
  my $dimms_num_status;
  my $dimms_num_log = "Has = " . $device_spec->dimms_num .", Want = " . $hw_profile->dimms_num;

  if ( $device_spec->dimms_num != $hw_profile->dimms_num ) {
    $dimms_num_status = 0;
    mistake("$device_id: report $report_id: CRITICAL: Incorrect DIMM count: $dimms_num_log");
  } else {
    $dimms_num_status = 1;
    trace("$device_id: report $report_id: OK: Correct DIMM count: $dimms_num_log");
  }

  $schema->resultset('DeviceValidate')->create({
    device_id       => $device_id,
    report_id       => $report_id,
    validation      => encode_json({
      component_type  => "RAM",
      component_name  => "dimm_count",
      metric          => $device_spec->dimms_num,
      log             => $dimms_num_log,
      status          => $dimms_num_status
    })
  });

  # Ensure we have correct amount of total RAM
  my $ram_total_status;
  my $ram_total_log = "Has = " . $device_spec->ram_total .", Want = " . $hw_profile->ram_total;

  if ( $device_spec->ram_total != $hw_profile->ram_total ) {
    $ram_total_status = 0;
    mistake("$device_id: report $report_id: CRITICAL: Incorrect RAM total: $ram_total_log");
  } else {
    $ram_total_status = 1;
    trace("$device_id: report $report_id: OK: Correct RAM total: $ram_total_log");
  }

  $schema->resultset('DeviceValidate')->create({
    device_id       => $device_id,
    report_id       => $report_id,
    validation      => encode_json({
      component_type  => "RAM",
      component_name  => "ram_total",
      metric          => $device_spec->ram_total,
      log             => $ram_total_log,
      status          => $ram_total_status
    })
  });
}

sub validate_nics_num {
  my ($schema, $device, $report_id) = @_;

  my $device_id   = $device->id;
  my $device_spec = $device->device_spec;
  my $hw_profile  = $device->hardware_product->hardware_product_profile;

  # Ensure we have correct number of network interfaces
  my $nics_num_status;
  my $nics_num_log = "Has = " . $device_spec->nics_num .", Want = " . $hw_profile->nics_num;

  if ( $device_spec->nics_num != $hw_profile->nics_num ) {
    $nics_num_status = 0;
    mistake("$device_id: report $report_id: CRITICAL: Incorrect number of network interfaces: $nics_num_log");
  } else {
    $nics_num_status = 1;
    trace("$device_id: report $report_id: OK: Correct number of network interfacesl: $nics_num_log");
  }

  $schema->resultset('DeviceValidate')->create({
    device_id       => $device_id,
    report_id       => $report_id,
    validation      => encode_json({
      component_type  => "NET",
      component_name  => "nics_num",
      metric          => $device_spec->nics_num,
      log             => $nics_num_log,
      status          => $nics_num_status
    })
  });

}

sub validate_bios_firmware {
  my ($schema, $device, $report_id) = @_;

  my $device_id   = $device->id;
  my $device_spec = $device->device_spec;
  my $hw_profile  = $device->hardware_product->hardware_product_profile;

  my $bios_version_status;
  my $bios_version_log = "Has = " . $device_spec->bios_firmware .", Want = " . $hw_profile->bios_firmware;

  if ( "$device_spec->bios_firmware" eq "$hw_profile->bios_firmware" ) {
    $bios_version_status = 0;
    mistake("$device_id: report $report_id: CRITICAL: Incorrect BIOS firmware version: $bios_version_log");
  } else {
    $bios_version_status = 1;
    trace("$device_id: report $report_id: OK: Correct BIOS firmware version: $bios_version_log");
  }

  $schema->resultset('DeviceValidate')->create({
    device_id       => $device_id,
    report_id       => $report_id,
    validation      => encode_json({
      component_type  => "BIOS",
      component_name  => "bios_firmware_version",
      metric          => $device_spec->bios_firmware,
      log             => $bios_version_log,
      status          => $bios_version_status
    })
  });

}

sub validate_disks {
  my ($schema, $device, $report_id) = @_;

  my $device_id = $device->id;
  trace("$device_id: report $report_id: Validating disk inventory");

  # TODO: Dep-dup with validate_system
  my $device_spec = $device->device_spec;
  my $hw_product  = $device->hardware_product;
  my $hw_profile  = $hw_product->hardware_product_profile;

  my $device_disks = $schema->resultset('DeviceDisk')->search({
    device_id => $device_id,
    deactivated => { '=', undef },
    transport   => { '!=', "usb" }
  });

  my $device_usbs = $schema->resultset('DeviceDisk')->search({
    device_id => $device_id,
    deactivated => { '=', undef },
    transport   => 'usb',
  });


  my $usb_hdd_num = 0;
  my $sas_hdd_num = 0;
  my $sas_ssd_num = 0;
  my $slog_slot;

  while ( my $disk = $device_disks->next ) {
    # If a disk/HBA/backplane goes back we'll often lose attributes. Fire a
    # flare if that happens.
    unless (defined $disk->slot) {
      my $disk_slot_msg = $disk->serial_number . "has no slot number defined. Bad disk, HBA, cable, backplane?";
      mistake("$device_id: report $report_id: CRITICAL: $disk_slot_msg");

      $schema->resultset('DeviceValidate')->create({
        device_id       => $device_id,
        report_id       => $report_id,
        validation      => encode_json({
          component_type  => "DISK",
          component_name  => "disk_slot_missing",
          metric          => $disk->serial_number,
          log             => $disk_slot_msg,
          status          => 0
        })
      });
    }

    unless (defined $disk->size) {
      my $disk_size_msg = $disk->serial_number . "has no disk size defined. Bad disk, HBA, cable, backplane?";
      mistake("$device_id: report $report_id: CRITICAL: $disk_size_msg");

      $schema->resultset('DeviceValidate')->create({
        device_id       => $device_id,
        report_id       => $report_id,
        validation      => encode_json({
          component_type  => "DISK",
          component_name  => "disk_size_missing",
          metric          => $disk->serial_number,
          log             => $disk_size_msg,
          status          => 0
        })
      });
    }

    if ( $disk->drive_type eq "SAS_HDD" ) {
      $sas_hdd_num++;
    }

    if ( $disk->drive_type eq "SAS_SSD" || $disk->drive_type eq "SATA_SSD" ) {
      # This gets overwritten if we have more than one SSD. But most systems are
      # mixed media. See below for the sas_ssd_num == 1 check.
      $slog_slot = $disk->slot;
      $sas_ssd_num++;
    }
  }

  while ( my $usb_disk = $device_usbs->next ) {
    $usb_hdd_num++;
  }

  # Ensure we have correct number of USB HDDs
  my $usb_hdd_num_status;
  my $usb_hdd_num_log = "Has = " . $usb_hdd_num .", Want = 1";

  if ( $usb_hdd_num != 1 ) {
    $usb_hdd_num_status = 0;
    mistake("$device_id: report $report_id: CRITICAL: Incorrect number of USB_HDD: $usb_hdd_num_log");
  } else {
    $usb_hdd_num_status = 1;
    trace("$device_id: report $report_id: OK: Correct number of USB_HDD: $usb_hdd_num_log");
  }

  $schema->resultset('DeviceValidate')->create({
    device_id       => $device_id,
    report_id       => $report_id,
    validation      => encode_json({
      component_type  => "DISK",
      component_name  => "usb_hdd_num",
      metric          => $usb_hdd_num,
      log             => $usb_hdd_num_log,
      status          => $usb_hdd_num_status
    })
  });

  # Ensure we have correct number of SAS HDDs
  my $sas_hdd_num_status;
  my $sas_hdd_num_log = "Has = " . $sas_hdd_num .", Want = " . $hw_profile->sas_num;

  if ( $sas_hdd_num != $hw_profile->sas_num ) {
    $sas_hdd_num_status = 0;
    mistake("$device_id: report $report_id: CRITICAL: Incorrect number of SAS_HDD: $sas_hdd_num_log");
  } else {
    $sas_hdd_num_status = 1;
    trace("$device_id: report $report_id: OK: Correct number of SAS_HDD: $sas_hdd_num_log");
  }

  $schema->resultset('DeviceValidate')->create({
    device_id       => $device_id,
    report_id       => $report_id,
    validation      => encode_json({
      component_type  => "DISK",
      component_name  => "sas_hdd_num",
      metric          => $sas_hdd_num,
      log             => $sas_hdd_num_log,
      status          => $sas_hdd_num_status
    })
  });

  # Ensure we have correct number of SAS SSDs
  my $sas_ssd_num_status;

  # Joyent-Compute-Platform-3302 special case.
  # HCs can have 8 or 16 SSD and there's no other identifier. Here, we want
  # to avoid missing failed/missing disks, so we jump through a couple extra
  # hoops.

  my $ssd_want = $hw_profile->ssd_num;

  if ( $hw_product->name eq "Joyent-Compute-Platform-3302" ) {
    if ( $sas_ssd_num <= 8 ) { $ssd_want = 8; }
    if ( $sas_ssd_num >  8 ) { $ssd_want = 16; }
  }
  my $sas_ssd_num_log = "Has = " . $sas_ssd_num .", Want = " . $ssd_want;

  if ( $sas_ssd_num != $ssd_want ) {
    $sas_ssd_num_status = 0;
    # XXX: Errors from SSD disabled due to SSD supply shortage. This will be
    # re-enabled when validations are modularized.
    info("$device_id: CRITICAL: report $report_id: Incorrect number of SAS_SSD: $sas_ssd_num_log");
    #mistake("$device_id: CRITICAL: report $report_id: Incorrect number of SAS_SSD: $sas_ssd_num_log");
  } else {
    $sas_ssd_num_status = 1;
    trace("$device_id: report $report_id: OK: Correct number of SAS_SSD: $sas_ssd_num_log");
  }

   $schema->resultset('DeviceValidate')->create({
    device_id       => $device_id,
    report_id       => $report_id,
    validation      => encode_json({
      component_type  => "DISK",
      component_name  => "sas_ssd_num",
      metric          => $sas_ssd_num,
      log             => $sas_ssd_num_log,
      status          => $sas_ssd_num_status
    })
  });

  # Ensure slog is in slot 0 on mixed media systems
  if ($sas_ssd_num == 1) {
    my $slog_slot_status;
    my $slog_slot_log = "Has = " . $slog_slot .", Want = 0";
    if ( $slog_slot != 0 ) {
      $slog_slot_status = 0;
      mistake("$device_id: report $report_id: CRITICAL: ZFS SLOG is in wrong slot: $slog_slot_log");
    } else {
      $slog_slot_status = 1;
      trace("$device_id: report $report_id: OK: ZFS SLOG is in correct slot: $slog_slot_log");
    }

    $schema->resultset('DeviceValidate')->create({
      device_id       => $device_id,
      report_id       => $report_id,
      validation      => encode_json({
        component_type  => "DISK",
        component_name  => "slog_slot",
        metric          => $slog_slot,
        log             => $slog_slot_log,
        status          => $slog_slot_status
      })
    });
  }
}

1;
