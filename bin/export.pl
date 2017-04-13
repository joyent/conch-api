#!/usr/bin/perl

use strict;
use warnings;

use JSON;
use Data::Printer;
use HTTP::Tiny;

use vars qw/@ARGV/;

sub read_ohai {
  my $filename = shift;

  my $generate_ohai = `ohai -c /var/chef/solo.rb > $filename`;

  my $json_text = do {
     open(my $json_fh, "<:encoding(UTF-8)", $filename)
        or die("Can't open $filename\": $!\n");
     local $/;
     <$json_fh>
  };

  my $json = JSON->new;
  my $ohai = $json->decode($json_text);

  return $ohai;
}

sub create_device {
  my $device = shift;

  my $response = HTTP::Tiny->new->post(
    "http://172.16.0.1:3000/device" => {
      content => to_json($device),
      headers => {
        "Content-Type" => "application/json",
      },
    },
  );

  print $response->{content};
}

# XXX
sub get_boot_order {
}

sub load_device {
  my ($device, $ohai ) = @_;

  my $serial_number = $ohai->{dmi}->{system}->{serial_number};

  $device->{serial_number} = $serial_number;
  $device->{product_name} = $ohai->{dmi}->{system}->{product_name};
  $device->{state}        = "ONLINE";
  $device->{health}       = "PASS";

  my $thermal_state = $ohai->{dmi}->{chassis}->{thermal_state};
  my $psu_state     = $ohai->{dmi}->{chassis}->{power_supply_state};
  
  if ($thermal_state ne "Safe") {
    warn "$thermal_state";
    $device->{health} = "FAIL";
  }

  if ($psu_state ne "Safe") {
    warn "$psu_state";
    $device->{health} = "FAIL";
  }

  $device->{bios_version} = $ohai->{dmi}->{bios}->{version};

  return $device;
}

sub load_hardware {
  my ( $device ) = @_;

  my $dimms = `dmidecode -t memory | grep Size | grep -v 'No Module' | wc -l`;
  chomp $dimms;
  $device->{memory}{count} = $dimms;

  my $mem_grep = `grep ^MemTotal /proc/meminfo | awk '{print \$2}'`;
  my $mem_total = $mem_grep / 1024;
  $mem_total =~ s/\..*$//;
  $device->{memory}{total} = $mem_total;

  # lshw JSON and XML output is broken in awesome ways, so we resort to this.
  my $output = `lshw -quiet -short > /tmp/lshw.out`;

  open(FILE, "/tmp/lshw.out") or die "Could not read file: $!";

  while(<FILE>) {
    chomp;
    my @line = split(/\s+/,$_);

    if ( $_ =~ /processor/ ){
      my $product = join(" ", splice(@line, 3, $#line));
      $device->{processor}{count}++;
      $device->{processor}{type} = $product ;
    }

    # Get network info.
    if ( $_ =~ /network/ ) {
      my $product = join(" ", splice(@line, 3, $#line));
      my $iface = $line[1];
      if ( $iface =~ /^eth/ && $product ) {
        $device->{interfaces}{$iface}{product} = $product;
   
        # XXX Don't start with me.
        $device->{interfaces}{$iface}{vendor} = "Intel";
      }
    }
  }

  close FILE;

  return $device;
}

sub load_interfaces {
  my ( $device, $ohai ) = @_;

   my $serial_number = $ohai->{dmi}->{system}->{serial_number};

  foreach my $iface (keys %{$ohai->{network}->{interfaces}}) {
    next unless $iface =~ /^eth/;
  
    my $mac;
    my $ipaddr;
  
    foreach my $addr (keys %{$ohai->{network}->{interfaces}->{$iface}->{addresses}}) {
      if ( $ohai->{network}->{interfaces}->{$iface}->{addresses}->{$addr}->{family} eq "lladdr" ) {
        $mac = $addr;
      }
  
      # This only supports one IP, which is fine for our use case.
      if ( $ohai->{network}->{interfaces}->{$iface}->{addresses}->{$addr}->{family} eq "inet" ) {
        $ipaddr = $addr;
      }
    }
  
    $device->{interfaces}{$iface}{ipaddr} = $ipaddr;
    $device->{interfaces}{$iface}{mac}    = $mac;
    $device->{interfaces}{$iface}{state}  = $ohai->{network}->{interfaces}->{$iface}->{state};
    $device->{interfaces}{$iface}{mtu}    = $ohai->{network}->{interfaces}->{$iface}->{mtu};
  
    my $switch_port;
    if ( exists $ohai->{lldp}->{$iface}->{port}->{ifname} ) {
      my $switch_port = $ohai->{lldp}->{$iface}->{port}->{ifname};
      $switch_port =~ s/TenGigabitEthernet //;
  
      $device->{interfaces}{$iface}{peer_port}   = $switch_port;
      $device->{interfaces}{$iface}{peer_switch} = $ohai->{lldp}->{$iface}->{chassis}->{name};
      $device->{interfaces}{$iface}{peer_mac}    = $ohai->{lldp}->{$iface}->{chassis}->{mac};
      $device->{interfaces}{$iface}{peer_text}   = $ohai->{lldp}->{$iface}->{chassis}->{name} . " " . $ohai->{lldp}->{$iface}->{port}->{ifname};
    }
  }
  
  return $device;
}

my $device = {};

my $ohai = read_ohai($ARGV[0]);

$device = load_hardware($device);
$device = load_interfaces($device, $ohai);
$device = load_device($device, $ohai);

create_device($device);
#p $device;
