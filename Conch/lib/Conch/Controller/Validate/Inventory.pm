package Conch::Controller::Validate::Inventory;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use Data::Printer;

=head1 NAME

Conch::Controller::Validate::Inventory - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Conch::Controller::Validate::Inventory in Validate::Inventory.');

    $c->forward('system');
    $c->forward('disks');
}

# XXX This is spaghetti. Abstract these checks by db field name or something.
sub system : Private {
  my ( $self, $c ) = @_;

  my $device_id = $c->req->data->{serial_number};
  $c->log->debug("$device_id: Validating system inventory");

  my $device = $c->model('DB::Device')->search({ id => $device_id})->single;

  my $device_spec = $c->model('DB::DeviceSpec')->search({
    device_id => $device_id,
  })->single;

  my $hw_profile = $c->model('DB::HardwareProductProfile')->search({
    id => $device_spec->product_id
  })->single;

  my $hw_product = $c->model('DB::HardwareProduct')->search({
    id => $hw_profile->product_id
  })->single;

  # Ensure we have correct number of CPUs
  my $cpu_num_status;
  my $cpu_num_log = "Has = " . $device_spec->cpu_num .", Want = " . $hw_profile->cpu_num;

  if ( $device_spec->cpu_num != $hw_profile->cpu_num ) {
    $cpu_num_status = 0;
    $c->log->debug("$device_id: CRITICAL: Incorrect CPU count: $cpu_num_log");
    $c->stash( fail => 1 );
  } else {
    $cpu_num_status = 1;
    $c->log->debug("$device_id: OK: Correct CPU count: $cpu_num_log");
  }

  my $cpu_num_record = $c->model('DB::DeviceValidate')->update_or_create({
    device_id       => $device_id,
    component_type  => "CPU",
    component_name  => "cpu_count",
    metric          => $device_spec->cpu_num,
    log             => $cpu_num_log,
    status          => $cpu_num_status
  });
 
  # Ensure we have correct number of DIMMs
  my $dimms_num_status;
  my $dimms_num_log = "Has = " . $device_spec->dimms_num .", Want = " . $hw_profile->dimms_num;

  if ( $device_spec->dimms_num != $hw_profile->dimms_num ) {
    $dimms_num_status = 0;
    $c->log->debug("$device_id: CRITICAL: Incorrect DIMM count: $dimms_num_log");
    $c->stash( fail => 1 );
  } else {
    $dimms_num_status = 1;
    $c->log->debug("$device_id: OK: Correct DIMM count: $dimms_num_log");
  }

  my $dimms_num_record = $c->model('DB::DeviceValidate')->update_or_create({
    device_id       => $device_id,
    component_type  => "RAM",
    component_name  => "dimm_count",
    metric          => $device_spec->dimms_num,
    log             => $dimms_num_log,
    status          => $dimms_num_status
  });

  # Ensure we have correct amount of total RAM
  my $ram_total_status;
  my $ram_total_log = "Has = " . $device_spec->ram_total .", Want = " . $hw_profile->ram_total;

  if ( $device_spec->ram_total != $hw_profile->ram_total ) {
    $ram_total_status = 0;
    $c->log->debug("$device_id: CRITICAL: Incorrect RAM total: $ram_total_log");
    $c->stash( fail => 1 );
  } else {
    $ram_total_status = 1;
    $c->log->debug("$device_id: OK: Correct RAM total: $ram_total_log");
  }

  my $ram_total_record = $c->model('DB::DeviceValidate')->update_or_create({
    device_id       => $device_id,
    component_type  => "RAM",
    component_name  => "ram_total",
    metric          => $device_spec->ram_total,
    log             => $ram_total_log,
    status          => $ram_total_status
  });

  # Ensure we have correct number of network interfaces
  my $nics_num_status;
  my $nics_num_log = "Has = " . $device_spec->nics_num .", Want = " . $hw_profile->nics_num;

  if ( $device_spec->nics_num != $hw_profile->nics_num ) {
    $nics_num_status = 0;
    $c->log->debug("$device_id: CRITICAL: Incorrect number of network interfaces: $nics_num_log");
    $c->stash( fail => 1 );
  } else {
    $nics_num_status = 1;
    $c->log->debug("$device_id: OK: Correct number of network interfacesl: $nics_num_log");
  }

  my $nics_num_record = $c->model('DB::DeviceValidate')->update_or_create({
    device_id       => $device_id,
    component_type  => "NET",
    component_name  => "nics_num",
    metric          => $device_spec->nics_num,
    log             => $nics_num_log,
    status          => $nics_num_status
  });

}

sub disks : Private {
  my ( $self, $c ) = @_;

  my $device_id = $c->req->data->{serial_number};
  $c->log->debug("$device_id: Validating disk inventory");

  my $device = $c->model('DB::Device')->find($device_id);

  my $device_spec = $c->model('DB::DeviceSpec')->search({
    device_id => $device_id,
  })->single;

  my $device_disk = $c->model('DB::DeviceDisk')->search({
    device_id => $device_id,
    deactivated => { '=', undef },
    transport   => { '!=', "usb" }
  });

  my $hw_profile = $c->model('DB::HardwareProductProfile')->search({
    id => $device_spec->product_id
  })->single;

  my $hw_product = $c->model('DB::HardwareProduct')->search({
    id => $hw_profile->product_id
  })->single;

  my $sas_hdd_num = 0;
  my $sas_ssd_num = 0;
  my $slog_slot;
 
  while ( my $disk = $device_disk->next ) {
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

  # Ensure we have correct number of SAS HDDs
  my $sas_hdd_num_status;
  my $sas_hdd_num_log = "Has = " . $sas_hdd_num .", Want = " . $hw_profile->sas_num;

  if ( $sas_hdd_num != $hw_profile->sas_num ) {
    $sas_hdd_num_status = 0;
    $c->log->debug("$device_id: CRITICAL: Incorrect number of SAS_HDD: $sas_hdd_num_log");
    $c->stash( fail => 1 );
  } else {
    $sas_hdd_num_status = 1;
    $c->log->debug("$device_id: OK: Correct number of SAS_HDD: $sas_hdd_num_log");
  }

  my $sas_hdd_num_record = $c->model('DB::DeviceValidate')->update_or_create({
    device_id       => $device_id,
    component_type  => "DISK",
    component_name  => "sas_hdd_num",
    metric          => $sas_hdd_num,
    log             => $sas_hdd_num_log,
    status          => $sas_hdd_num_status
  });

  # Ensure we have correct number of SAS SSDs
  my $sas_ssd_num_status;
  my $sas_ssd_num_log = "Has = " . $sas_ssd_num .", Want = " . $hw_profile->ssd_num;

  if ( $sas_ssd_num != $hw_profile->ssd_num ) {
    $sas_ssd_num_status = 0;
    $c->log->debug("$device_id: CRITICAL: Incorrect number of SAS_SSD: $sas_ssd_num_log");
    $c->stash( fail => 1 );
  } else {
    $sas_ssd_num_status = 1;
    $c->log->debug("$device_id: OK: Correct number of SAS_SSD: $sas_ssd_num_log");
  }

  my $sas_ssd_num_record = $c->model('DB::DeviceValidate')->update_or_create({
    device_id       => $device_id,
    component_type  => "DISK",
    component_name  => "sas_ssd_num",
    metric          => $sas_ssd_num,
    log             => $sas_ssd_num_log,
    status          => $sas_ssd_num_status
  });

  # Ensure slog is in slot 0 on mixed media systems
  if ($sas_ssd_num == 1) {
    my $slog_slot_status;
    my $slog_slot_log = "Has = " . $slog_slot .", Want = 0";
    if ( $slog_slot != 0 ) {
      $slog_slot_status = 0;
      $c->log->debug("$device_id: CRITICAL: ZFS SLOG is in wrong slot: $slog_slot_log");
      $c->stash( fail => 1 );
    } else {
      $slog_slot_status = 1;
      $c->log->debug("$device_id: OK: ZFS SLOG is in correct slot: $slog_slot_log");
    }

    my $slog_slot_record = $c->model('DB::DeviceValidate')->update_or_create({
      device_id       => $device_id,
      component_type  => "DISK",
      component_name  => "slog_slot",
      metric          => $slog_slot,
      log             => $slog_slot_log,
      status          => $slog_slot_status
    });
  }
}

=encoding utf8

=head1 AUTHOR

Super-User

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
