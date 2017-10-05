package Conch::Control::Rack;

use strict;
use Log::Any '$log';
use Dancer2::Plugin::Passphrase;
use Conch::Control::User;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( get_rack racks_for_user rack_roles rack_layout );

sub get_rack {
  my ( $schema, $rack_id ) = @_;
  my $rack = $schema->resultset('DatacenterRack')->find( { id => $rack_id } );
  return $rack;
}

sub rack_roles {
  my ($schema) = @_;

  my %rack_roles;
  my @rack_roles = $schema->resultset('DatacenterRackRole')->search( {} )->all;

  foreach my $rack_role (@rack_roles) {
    $rack_roles{ $rack_role->id }{name} = $rack_role->name;
    $rack_roles{ $rack_role->id }{size} = $rack_role->rack_size;
  }

  return \%rack_roles;
}

sub racks_for_user {
  my ( $schema, $user_name ) = @_;

  my @racks = $schema->resultset('UserRackAccess')
    ->search( {}, { bind => [$user_name] } )->all;

  my @datacenter_room = $schema->resultset('DatacenterRoom')->search( {} )->all;

  my $rack_progress = {};
  my @rack_progress =
    $schema->resultset('RackDeviceProgress')->search( {} )->all;
  for my $rp (@rack_progress) {
    $rack_progress->{ $rp->rack_id }->{ $rp->status } = $rp->count;
  }

  my %dc;
  foreach my $dc (@datacenter_room) {
    $dc{ $dc->id }{name}   = $dc->az;
    $dc{ $dc->id }{region} = $dc->datacenter->region;
  }

  my $rack_roles = rack_roles($schema);

  my $user_racks = {};
  foreach my $rack (@racks) {
    my $rack_dc   = $dc{ $rack->datacenter_room_id }{name};
    my $user_rack = {};
    $user_rack->{id}              = $rack->id;
    $user_rack->{name}            = $rack->name;
    $user_rack->{role}            = $rack_roles->{ $rack->role }{name};
    $user_rack->{size}            = $rack_roles->{ $rack->role }{size};
    $user_rack->{device_progress} = $rack_progress->{ $rack->id } || {};
    push @{ $user_racks->{$rack_dc} }, $user_rack;
  }

  return $user_racks;
}

sub rack_layout {
  my ( $schema, $uuid ) = @_;

  my @datacenter_room = $schema->resultset('DatacenterRoom')->search( {} )->all;

  my %dc;
  foreach my $dc (@datacenter_room) {
    $dc{ $dc->id }{name}   = $dc->az;
    $dc{ $dc->id }{region} = $dc->datacenter->region;
  }

  my @rack_slots = $schema->resultset('DatacenterRackLayout')->search(
    {
      rack_id => $uuid
    }
  );
  @rack_slots or die $log->error("Rack $uuid not found");

  my $rack_info = $schema->resultset('DatacenterRack')->find(
    {
      id => $uuid
    }
  );

  my $rack;
  $rack->{id}         = $uuid;
  $rack->{name}       = $rack_info->name;
  $rack->{role}       = $rack_info->role->name;
  $rack->{datacenter} = $dc{ $rack_info->datacenter_room_id }{name};

  foreach my $slot (@rack_slots) {
    my $hw = $schema->resultset('HardwareProduct')->find(
      {
        id => $slot->product_id
      }
    );

    my $hw_profile = $hw->hardware_product_profile;
    $hw_profile
      or die->error("Hardware product "
      . $slot->product_id
      . " exists but does not have a hardware profile");

    my $device_location = $schema->resultset('DeviceLocation')->find(
      {
        rack_id   => $uuid,
        rack_unit => $slot->ru_start
      }
    );

    if ($device_location) {
      my $device = { $device_location->device->get_columns };
      $rack->{slots}{ $slot->ru_start }{occupant} = $device;
    }
    else {
      $rack->{slots}{ $slot->ru_start }{occupant} = undef;
    }

    $rack->{slots}{ $slot->ru_start }{id}     = $hw->id;
    $rack->{slots}{ $slot->ru_start }{alias}  = $hw->alias;
    $rack->{slots}{ $slot->ru_start }{name}   = $hw->name;
    $rack->{slots}{ $slot->ru_start }{vendor} = $hw->vendor->name;
    $rack->{slots}{ $slot->ru_start }{size}   = $hw_profile->rack_unit;
  }

  return $rack;
}

1;
