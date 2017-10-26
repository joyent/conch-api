package Conch::Control::Rack;

use strict;
use Log::Any '$log';
use Dancer2::Plugin::Passphrase;
use Conch::Control::User;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( get_rack workspace_racks workspace_rack rack_roles rack_layout );

sub get_rack {
  my ( $schema, $rack_id ) = @_;
  my $rack = $schema->resultset('DatacenterRack')->find( { id => $rack_id } );
  return $rack;
}

sub rack_roles {
  my ($schema) = @_;
  my @rack_roles = $schema->resultset('DatacenterRackRole')->search( {} )->all;
  my $rack_roles = {};
  foreach my $rack_role (@rack_roles) {
    $rack_roles->{ $rack_role->id }->{name} = $rack_role->name;
    $rack_roles->{ $rack_role->id }->{size} = $rack_role->rack_size;
  }
  return $rack_roles;
}

sub workspace_racks {
  my ( $schema, $workspace_id ) = @_;

  my @racks = $schema->resultset('WorkspaceRacks')
    ->search( {}, { bind => [$workspace_id] } )->all;

  my @datacenter_room = $schema->resultset('DatacenterRoom')->search(
    {'workspace_datacenter_rooms.workspace_id' => $workspace_id},
    { join => 'workspace_datacenter_rooms' }
  )->all;

  my @rack_ids = map { $_->id } @racks;
  my $rack_progress = {};
  my @rack_progress =
    $schema->resultset('RackDeviceProgress')
    ->search( {rack_id => {-in => \@rack_ids } } )->all;
  for my $rp (@rack_progress) {
    $rack_progress->{ $rp->rack_id }->{ $rp->status } = $rp->count;
  }

  my %dc;
  foreach my $dc (@datacenter_room) {
    $dc{ $dc->id }{name}   = $dc->az;
    $dc{ $dc->id }{region} = $dc->datacenter->region;
  }

  my $rack_roles = rack_roles($schema);

  my $rack_groups = {};
  foreach my $rack (@racks) {
    my $rack_dc   = $dc{ $rack->datacenter_room_id }{name};
    my $rack_res = {};
    $rack_res->{id}              = $rack->id;
    $rack_res->{name}            = $rack->name;
    $rack_res->{role}            = $rack_roles->{ $rack->role }{name};
    $rack_res->{size}            = $rack_roles->{ $rack->role }{size};
    $rack_res->{device_progress} = $rack_progress->{ $rack->id } || {};
    push @{ $rack_groups->{$rack_dc} }, $rack_res;
  }

  return $rack_groups;
}

sub workspace_rack {
  my ( $schema, $workspace_id, $uuid ) = @_;

  return $schema->resultset('WorkspaceRacks')
    ->find( { id => $uuid }, { bind => [$workspace_id] } );
}

sub rack_layout {
  my ( $schema, $rack ) = @_;

  my @rack_slots = $schema->resultset('DatacenterRackLayout')->search(
    { rack_id => $rack->id }
  );

  my $datacenter_room = $schema->resultset('DatacenterRoom')->find(
    { id => $rack->datacenter_room_id }
  );

  my $res;
  $res->{id}         = $rack->id;
  $res->{name}       = $rack->name;
  $res->{role}       = $rack->role->name;
  $res->{datacenter} = $datacenter_room->az;

  foreach my $slot (@rack_slots) {
    my $hw = $schema->resultset('HardwareProduct')->find(
      {
        id => $slot->product_id
      }
    );

    my $hw_profile = $hw->hardware_product_profile;
    $hw_profile
      or die->error( "Hardware product "
        . $slot->product_id
        . " exists but does not have a hardware profile" );

    my $device_location = $schema->resultset('DeviceLocation')->find(
      {
        rack_id   => $rack->id,
        rack_unit => $slot->ru_start
      }
    );

    if ($device_location) {
      my $device = { $device_location->device->get_columns };
      $res->{slots}{ $slot->ru_start }{occupant} = $device;
    }
    else {
      $res->{slots}{ $slot->ru_start }{occupant} = undef;
    }

    $res->{slots}{ $slot->ru_start }{id}     = $hw->id;
    $res->{slots}{ $slot->ru_start }{alias}  = $hw->alias;
    $res->{slots}{ $slot->ru_start }{name}   = $hw->name;
    $res->{slots}{ $slot->ru_start }{vendor} = $hw->vendor->name;
    $res->{slots}{ $slot->ru_start }{size}   = $hw_profile->rack_unit;
  }

  return $res;
}

1;
