#!/usr/bin/perl

# XXX Write some DBIC code or just shell escapes to loop through wiremap file,
# XXX query database for registered SNs. If we see it, import the wiremap. If
# XXX not, log we're skipping it, and skip it.

use strict;
use warnings;

use Text::CSV;
use Data::Printer;

my $file = $ARGV[0];

my $hosts = {};

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

    #print "$sn $mac $iface $switch:$port\n";

    $hosts->{$sn}->{nics}->{$mac}->{iface} = $iface;
    $hosts->{$sn}->{nics}->{$mac}->{want_switch} = $switch;
    $hosts->{$sn}->{nics}->{$mac}->{want_port} = $port;
     
    $i = $i+3;
  }
  $line++;
}

p $hosts;
