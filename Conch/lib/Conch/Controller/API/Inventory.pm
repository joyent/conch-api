package Conch::Controller::API::Inventory;
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

sub inventory : Local : ActionClass('REST') { }

sub inventory_GET :Path('/inventory/device') {
  my ( $self, $c, $sn ) = @_;

  my $req = $c->req->data;

  $c->stash(datacenter => $c->config->{datacenter});

  my $device = $c->model("DB::Device")->find($sn);
  my @col = $device->columns;
  foreach my $col (@col) {
    # Some elements of device will return an object. Timestamp or a DBIC RS.
    if ( ref $device->$col ) {
      if ($device->$col->isa("DateTime")) {
        my $dt = $device->$col;
        my $stamp = $dt->ymd . " " . $dt->hour.":".$dt->minute.":".$dt->second;
        $c->stash($col => $stamp);
      }
    }
    else {
      $c->stash($col => $device->$col);
    }
  }

  my %spec;
  my $specs = $c->model("DB::DeviceSpec")->find($sn);
  my @spcol = $specs->columns;
  foreach my $spcol (@spcol) {
    $spec{$spcol} = $specs->$spcol;
  }
  $c->stash(inventory => { %spec });

  my $hw_product = $device->hardware_product;
  $c->stash(
    product => {
      name   => $hw_product->name,
      alias  => $hw_product->alias,
      prefix => $hw_product->prefix,
    }
  );

  my $hw_profile = $c->model("DB::HardwareProductProfile")->search({product_id => $hw_product->id})->single;
  my %profile;
  if ( $hw_profile ) {
    my @hwcol = $hw_profile->columns;
    foreach my $hwcol (@hwcol) {
      if ( ref $hw_profile->$hwcol ) {
        next if $hw_profile->$hwcol->isa("DateTime");
      }
      else {
        $profile{$hwcol} = $hw_profile->$hwcol;
      }
    }
  }

  $c->stash(product_profile => { %profile });

  my $location = $c->model("DB::DeviceLocation")->find($sn);
  if (defined $location) {
    my $rack = $c->model("DB::DatacenterRack")->find($location->rack_id);
    my $dc_room = $c->model("DB::DatacenterRoom")->find($rack->datacenter_room_id);
    $c->stash(
      location => {
        rack_unit  => $location->rack_unit,
        rack_num   => $rack->name,
        datacenter => $dc_room->az,
      }
    )
  }

  my %nics;
  my $nics = $c->model("DB::DeviceNic")->search({ device_id => $device->id });

  while (my $nic = $nics->next) {
    my $neighbor = $c->model("DB::DeviceNeighbor")->find($nic->mac);

    # if ( eval{ $neighbor->can('peer_switch') } )  {
    if (defined $neighbor->want_switch) {
      $nics{$nic->mac}{want_sup} = $neighbor->want_switch . " " . $neighbor->want_port;
    }

    if (defined $neighbor->peer_switch) {
      $nics{$nic->mac}{peer_sup} = $neighbor->peer_switch . " " . $neighbor->peer_port;
    }
  }

  $c->stash(network => { %nics });

  $self->status_ok(
    $c,
    entity => { },
  );

  $c->forward('View::JSON');
}

__PACKAGE__->meta->make_immutable;

1;
