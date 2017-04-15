package Conch::Controller::API::Device;
use Moose;
use namespace::autoclean;

use JSON;
use Data::UUID;
use Data::Printer;

BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
  default   => 'application/json',
  default_view => 'JSON',
  namespace   => '',
);

sub device : Local : ActionClass('REST') { }

sub device_POST :Path('/api/device') {
  my ( $self, $c ) = @_;

  my $req = $c->req->data;

  my $hw_rs = $c->model('DB::HardwareProduct')->search({
    name => $req->{product_name}
  });

  my $hw = $hw_rs->first;

  my $hw_profile_rs = $c->model('DB::HardwareProductProfile')->search({
    product_id       => $hw->id
  });

  my $hw_profile = $hw_profile_rs->first;

  my $device_rs = $c->model('DB::Device')->update_or_create({
    id               => $req->{system_uuid},
    hardware_product => $hw->id,
    serial_number    => $req->{serial_number},
    state            => $req->{state},
    health           => $req->{health},
  });

  my %interfaces = %{$req->{interfaces}};
  my $nics_num = keys %interfaces;

  my $device_specs = $c->model('DB::DeviceSpec')->update_or_create({
    device_id       => $device_rs->id,
    product_id      => $hw_profile->id,
    bios_firmware   => $req->{bios_version},
    cpu_num         => $req->{processor}->{count},
    cpu_type        => $req->{processor}->{type},
    nics_num        => $nics_num,
    dimms_num       => $req->{memory}->{count},
    ram_total       => $req->{memory}->{total},
  });

  my $device_temps = $c->model('DB::DeviceTempurature')->update_or_create({
    device_id       => $device_rs->id,
    cpu0_temp       => $req->{temp}->{cpu0},
    cpu1_temp       => $req->{temp}->{cpu1},
    inlet_temp      => $req->{temp}->{inlet},
    exhaust_temp    => $req->{temp}->{exhaust},
  });

  foreach my $disk (keys %{$req->{disks}}) {
    my $disk_rs = $c->model('DB::DeviceDisk')->update_or_create({
      device_id       => $device_rs->id,
      serial_number   => $disk,
      slot            => $req->{disks}->{$disk}->{slot},
      hba             => $req->{disks}->{$disk}->{hba},
      vendor          => $req->{disks}->{$disk}->{vendor},
      health          => $req->{disks}->{$disk}->{health},
      size            => $req->{disks}->{$disk}->{size},
      model           => $req->{disks}->{$disk}->{model},
      temp            => $req->{disks}->{$disk}->{temp},
      drive_type      => $req->{disks}->{$disk}->{drive_type},
      transport       => $req->{disks}->{$disk}->{transport},
      firmware        => $req->{disks}->{$disk}->{firmware},
    });
  }

  foreach my $nic (keys %{$req->{interfaces}}) {
    my $nic_rs = $c->model('DB::DeviceNic')->update_or_create({
      mac           => $req->{interfaces}->{$nic}->{mac},
      device_id     => $device_rs->id,
      iface_name    => $nic,
      iface_type    => $req->{interfaces}->{$nic}->{product},
      iface_vendor  => $req->{interfaces}->{$nic}->{vendor},
      iface_driver  => "",
    });

    my $nic_state = $c->model('DB::DeviceNicState')->update_or_create({
      nic_id        => $req->{interfaces}->{$nic}->{mac},
      state         => $req->{interfaces}->{$nic}->{state},
      ipaddr        => $req->{interfaces}->{$nic}->{ipaddr},
      mtu           => $req->{interfaces}->{$nic}->{mtu},
    });

    my $nic_peers = $c->model('DB::DeviceNeighbor')->update_or_create({
      nic_id        => $req->{interfaces}->{$nic}->{mac},
      raw_text      => $req->{interfaces}->{$nic}->{peer_text},
      peer_switch   => $req->{interfaces}->{$nic}->{peer_switch},
      peer_port     => $req->{interfaces}->{$nic}->{peer_port},
    });
  }

  $self->status_ok(
    $c,
    entity => {
      action  => "create",
      uuid    => $device_rs->id,
      status  => "200"
    }
  );

  $c->forward('View::JSON');
}

__PACKAGE__->meta->make_immutable;

1;
