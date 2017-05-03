#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;

my $rooms = {};

my $psql = "psql -d preflight -U preflight -q -t -A";

open(FILE, "./datacenter_ap_se_racks.txt") or die "Could not read file: $!";
while(<FILE>) {
  chomp;
  my ( $dc, $rack, $size, $role ) = split(/\s+/,$_);
  my $dc_id = `$psql -c "SELECT id FROM datacenter_room WHERE az = '$dc'"`;
  print "$dc $rack $size $role\n";
  my $INSERT_SQL = "INSERT INTO datacenter_rack (datacenter_room_id, name, rack_size, role)"
  my $VALUES_SQL = "VALUES ('$dc_id', '$rack', $size, '$role')";
  print "$INSERT_SQL $VALUES_SQL";
}
