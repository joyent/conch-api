#!/usr/bin/env perl

use strict;
use warnings;
use Data::Printer;

my $rooms = {};

my $psql = "psql -d preflight -U preflight -q -t -A";

my $a_id = `$psql -c "SELECT id FROM datacenter_room WHERE az = 'eu-central-1a'"`;
chomp $a_id;

$rooms->{'eu-central-1a'} = $a_id;

my $b_id = `$psql -c "SELECT id FROM datacenter_room WHERE az = 'eu-central-1b'"`;
chomp $b_id;

$rooms->{'eu-central-1b'} = $b_id;

my $c_id = `$psql -c "SELECT id FROM datacenter_room WHERE az = 'eu-central-1c'"`;
chomp $c_id;

$rooms->{'eu-central-1c'} = $c_id;

open(FILE, "./datacenter_eu_ams_racks.txt") or die "Could not read file: $!";
while(<FILE>) {
  chomp;
  my ( $dc, $rack, $size, $role ) = split(/\s+/,$_);
  my $dc_id = $rooms->{$dc};
  print "$dc $rack $role\n";
  my $update = `$psql -c \"UPDATE datacenter_rack SET role = '$role' WHERE datacenter_room_id = '$dc_id' AND name = '$rack'\";`;
  print "$update\n";
}
