package Conch::Control::Rack;

use strict;
use Log::Report;
use Dancer2::Plugin::Passphrase;
use Conch::Control::User;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( racks_for_user rack_roles );

sub rack_roles {
  my ($schema) = @_;

  my %rack_roles;
  my @rack_roles = $schema->resultset('DatacenterRackRole')->
    search({})->all;

  foreach my $rack_role (@rack_roles) {
    $rack_roles{ $rack_role->id }{name} = $rack_role->name;
    $rack_roles{ $rack_role->id }{size} = $rack_role->rack_size;
  }

  return \%rack_roles;
}

sub racks_for_user {
  my ($schema, $user_name) = @_;

  my @racks = $schema->resultset('UserRackAccess')->
    search({}, { bind => [$user_name] })->all;

  my @datacenter_room = $schema->resultset('DatacenterRoom')->
    search({})->all;

  my %dc;
  foreach my $dc (@datacenter_room) {
    $dc{ $dc->id }{name} = $dc->az;
    $dc{ $dc->id }{region} = $dc->datacenter->region;
  }

  my $rack_roles = rack_roles($schema);

  my $user_racks = {};
  foreach my $rack (@racks) {
    my $rack_dc = $dc{ $rack->datacenter_room_id }{name};
    $user_racks->{ $rack_dc }{ $rack->id }{ name } = $rack->name;
    $user_racks->{ $rack_dc }{ $rack->id }{ role } = $rack_roles->{ $rack->role }{name};
    $user_racks->{ $rack_dc }{ $rack->id }{ size } = $rack_roles->{ $rack->role }{size};
  }

  return $user_racks;
}

1;
