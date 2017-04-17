#!/usr/bin/perl

# This script loads a dump from device42 (genreated by bspringall@), and emits
# several SQL files which can be loaded into Conch. This allows us to preload
# all devices for a given datacenter.
#
# Given a properly formatted input file, this script will emit records for the
# following tables:
#
# device
# device_location
# device_nic
# device_neighbor
#
# Information we don't yet possess (like system_uuid) will be marked UNKNOWN and
# filled in on the first Conch client run.
#
# Enjoy the printf.

use strict;
use warnings;

use Text::CSV;
use Data::Printer;

my $file = $ARGV[0];
my $psql = "psql -d preflight -U preflight";

print "Reticulating splines. Generating device, location, nic, and neighbor records.\n";

# Fake this until the host checks in.
my $dell_product = `$psql -q -t -A -c "SELECT id FROM hardware_product where name = 'Joyent-Compute-Platform-3301'"`;
chomp $dell_product;

my $smci_product = `$psql -q -t -A -c "SELECT id FROM hardware_product where name = 'Joyent-Storage-Platform-7001'"`;
chomp $smci_product;

die unless $dell_product;
die unless $smci_product;

my %dc_rooms;
my $am1 = `$psql -q -t -A -c "SELECT id FROM datacenter_room where vendor_name = 'AM1'`;
chomp $am1;
my $am3 = `$psql -q -t -A -c "SELECT id FROM datacenter_room where vendor_name = 'AM3'`;
chomp $am3;
my $am6 = `$psql -q -t -A -c "SELECT id FROM datacenter_room where vendor_name = 'AM6'`;
chomp $am6;

$dc_rooms{AM1} = $am1;
$dc_rooms{AM3} = $am3;
$dc_rooms{AM6} = $am6;

my $hosts = {};

open(my $device_fh, '>', "/tmp/device.sql");
open(my $device_location_fh, '>', "/tmp/device_location.sql");
open(my $device_nic_fh, '>', "/tmp/device_nic.sql");

my $csv = Text::CSV->new ( { binary => 1 } )
  or die "Cannot use CSV: ".Text::CSV->error_diag ();

my $line = 1;
open my $fh, "<:encoding(utf8)", $file or die "$!";
while ( my $row = $csv->getline( $fh ) ) {
  my $num = @$row;

  # Switches are included, but we don't need them.
  next unless ($num > 5);

  # DC, ROOM, RACK, RU, SN, (MAC, IFACE, PEER), (MAC, IFACE, PEER), (MAC, IFACE, PEER), (MAC, IFACE, PEER), (BMC_MAC, ipmi1, BMC_PEER)

  my ( $dc, $room, $rack, $ru, $sn ) = @$row[0..4];

  # This is pretty lame, but it'll be fixed the first time the agent runs.
  if ( $sn =~ /^S247/ ){
    $hosts->{$sn}->{product_uuid} = $smci_product;
  } else {
    $hosts->{$sn}->{product_uuid} = $dell_product;
  }

  my $room_id = $dc_rooms{$room};
  my $rack_id = `$psql -q -t -A -c "SELECT id FROM datacenter_rack where name = '$rack' and datacenter_room_id = '$room_id'`;
  chomp $rack_id;
  
  printf $device_fh "INSERT INTO device (id, hardware_product, state, health) VALUES ('%s', '%s', '%s', '%s');\n",
    $sn, $hosts->{$sn}->{product_uuid}, "UNKNOWN", "UNKNOWN";

  # device42 givues us floats for RU, and it starts on 0 instead of 1.
  $ru =~ s/\..*$//;
  $ru++;

  printf $device_location_fh "INSERT INTO device_location (device_id, rack_id, rack_unit) VALUES ('%s', '%s', '%s');\n",
    $sn, $rack_id, $ru;

  my @row = @$row;
  my @interfaces = @$row[5 .. $#row];

  my $i = 0;
  my $length = scalar @interfaces;
  $length--;
  while ($i <= $length) {
    my $mac   = $interfaces[$i];
    my $iface = $interfaces[$i+1];
    my $peer  = $interfaces[$i+2];

    $peer =~ s/^\s+|\s+$//g;
    
    my ( $port, $switch) = split(/ @ /,$peer);
    $port =~ s/^te//;

    #print "$sn $mac $iface $switch:$port\n";

    printf $device_nic_fh "INSERT INTO device_nic (mac, device_id, iface_name, iface_type, iface_vendor) VALUES ('%s', '%s', '%s', '%s', '%s');\n",
      $mac, $sn, $iface, "UNKNOWN", "UNKNOWN";

    printf $device_nic_fh "INSERT INTO device_neighbor (mac, want_switch, want_port) VALUES ('%s', '%s', '%s');\n",
      $mac, $switch, $port;
     
    $i = $i+3;
  }
  $line++;
}

print "Done.\n\n";

close $device_fh;
close $device_location_fh;
close $device_nic_fh;

print <<EOF
Assuming all went well, you can now run:

psql -d preflight -U preflight < /tmp/device.sql
psql -d preflight -U preflight < /tmp/device_location.sql
psql -d preflight -U preflight < /tmp/device_nic.sql
EOF



