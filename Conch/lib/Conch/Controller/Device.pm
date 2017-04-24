package Conch::Controller::Device;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use Data::Printer;

=head1 NAME

Conch::Controller::Device - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
  my ( $self, $c ) = @_;

  $c->forward('view');
}

sub view : Local {
  my ( $self, $c, $sn ) = @_;

  # XXX If sn doesn't exist, error out.

  my $host = {};

  $c->stash(datacenter => $c->config->{datacenter});

  # Device basics from device table
  my $device = $c->model("DB::Device")->find($sn);
  $host->{id} = $device->id;
  $host->{health} = $device->health;

  my $hw_product = $device->hardware_product;
  $host->{product_name}   = $hw_product->name;
  $host->{product_alias}  = $hw_product->alias;
  $host->{product_prefix} = $hw_product->prefix;

  my $location = $c->model("DB::DeviceLocation")->find($sn);
  if (defined $location) {
    $host->{rack_unit} = $location->rack_unit;

    my $rack = $c->model("DB::DatacenterRack")->find($location->rack_id);
    $host->{rack_num} = $rack->name;

    my $dc_room = $c->model("DB::DatacenterRoom")->find($rack->datacenter_room_id);
    $host->{dc_name} = $dc_room->az;
  }

  # Device network map
  my $nics = $c->model("DB::DeviceNic")->search({ device_id => $device->id });
 
  while (my $nic = $nics->next) {
    my $state = $c->model("DB::DeviceNicState")->find($nic->mac);
    if (defined $state) {
      $host->{nics}{$nic->mac}{state}  = $state->state;
      $host->{nics}{$nic->mac}{ipaddr} = $state->ipaddr;
    }

    $host->{nics}{$nic->mac}{name}   = $nic->iface_name;
    $host->{nics}{$nic->mac}{type}   = $nic->iface_type;

    my $neighbor = $c->model("DB::DeviceNeighbor")->find($nic->mac);

    if (defined $neighbor->want_switch) {
      $host->{nics}{$nic->mac}{want_sup} = $neighbor->want_switch . " " . $neighbor->want_port;
    }

    if (defined $neighbor->peer_switch) {
      $host->{nics}{$nic->mac}{peer_sup} = $neighbor->peer_switch . " " . $neighbor->peer_port;
    }
  }

  my $device_env = $c->model("DB::DeviceEnvironment")->find($device->id);
  $host->{env}{cpu0}    = $device_env->cpu0_temp;
  $host->{env}{cpu1}    = $device_env->cpu1_temp;
  $host->{env}{inlet}   = $device_env->inlet_temp;
  $host->{env}{exhaust} = $device_env->exhaust_temp;

  my $disks = $c->model("DB::DeviceDisk")->search({ device_id => $device->id });
  while (my $disk = $disks->next) {
    $host->{disks}{$disk->serial_number}{hba}        = $disk->hba;
    $host->{disks}{$disk->serial_number}{slot}       = $disk->slot;
    $host->{disks}{$disk->serial_number}{health}     = $disk->health;
    $host->{disks}{$disk->serial_number}{temp}       = $disk->temp;
    $host->{disks}{$disk->serial_number}{vendor}     = $disk->vendor;
    $host->{disks}{$disk->serial_number}{model}      = $disk->model;
    $host->{disks}{$disk->serial_number}{size}       = $disk->size;
    $host->{disks}{$disk->serial_number}{drive_type} = $disk->drive_type;
    $host->{disks}{$disk->serial_number}{size}       = $disk->size;
    $host->{disks}{$disk->serial_number}{transport}  = $disk->transport;
    $host->{disks}{$disk->serial_number}{firmware}   = $disk->firmware;
  }

  # Get most recent port for host
  # If no report_id, .. guess.

  my $last_report = $c->model("DB::DeviceValidate")->search({
      device_id => $device->id,
      report_id => { '!=', undef },
    },
    { order_by => { -desc => 'created' }
  })->single;

  if (defined $last_report) {
    my $report;
    if (defined $last_report->report_id) {
      $c->stash(report => [$c->model("DB::DeviceValidate")->search(
        { report_id => $last_report->report_id, },
        { order_by => { -asc => 'created' }
     }) ]);
    } 
  }

  $c->stash(device => $device);
  $c->stash(host => $host);
  $c->stash(template => 'device.tt2');

  $c->forward('View::HTML');
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
