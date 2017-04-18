#!/usr/bin/perl

use strict;
use warnings;

use JSON;
use Data::Printer;
use HTTP::Tiny;

use vars qw/@ARGV/;

sub read_ohai {
  my $filename = "/tmp/ohai.json";
  my $generate_ohai = `/usr/bin/ohai -c /var/chef/solo.rb > $filename 2> /tmp/ohai.err`;

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
  $device->{product_name}  = $ohai->{dmi}->{system}->{product_name};
  $device->{system_uuid}   = $ohai->{dmi}->{system}->{uuid};
  $device->{state}         = "ONLINE";
  $device->{health}        = "PASS";

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

  my $dimms = `/usr/sbin/dmidecode -t memory | grep Size | grep -v 'No Module' | wc -l`;
  chomp $dimms;
  $device->{memory}{count} = $dimms;

  my $mem_grep = `/bin/grep ^MemTotal /proc/meminfo | awk '{print \$2}'`;
  my $mem_total = $mem_grep / 1024;
  $mem_total =~ s/\..*$//;
  $device->{memory}{total} = $mem_total;

  # lshw JSON and XML output is broken in awesome ways, so we resort to this.
  my $output = `/usr/bin/lshw -quiet -short > /tmp/lshw.out`;

  open(FILE, "/tmp/lshw.out") or die "Could not read file: $!";

  while(<FILE>) {
    chomp;
    my @line = split(/\s+/,$_);

    if ( $_ =~ /processor/ ){
      my $product = join(" ", splice(@line, 3, $#line));
      $device->{processor}{count}++;
      $device->{processor}{type} = "Intel(R) $product";
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

# Dell:
# Inlet Temp       | 23 degrees C      | ok
# Exhaust Temp     | 41 degrees C      | ok
# Temp             | 41 degrees C      | ok
# Temp             | 52 degrees C      | ok
#
# SMCI:
# CPU1 Temp        | 38 degrees C      | ok
# CPU2 Temp        | 38 degrees C      | ok
# PCH Temp         | 32 degrees C      | ok
# System Temp      | 29 degrees C      | ok
# Peripheral Temp  | 33 degrees C      | ok
sub get_temp {
  my ($device) = @_;
  
  my $ipmi_sensors = `/usr/bin/ipmitool sdr | grep Temp`;
  chomp $ipmi_sensors;

  for (split/^/,$ipmi_sensors) {
    chomp;
    my ($k, $v, $status) = split/\|/, $_;

    $v =~ s/ degrees C//;

    $k =~ s/^\s+|\s+$//g;
    $v =~ s/^\s+|\s+$//g;
    $status =~ s/^\s+|\s+$//g;

    if ( $k =~ /^Inlet Temp|^System Temp/ ) {
      $device->{temp}->{inlet} = $v;
    }

    if ( $k =~ /^Exhaust Temp|^Peripheral Temp/ ) {
      $device->{temp}->{exhaust} = $v;
    }

    if ( $k =~ /^CPU1 Temp/ ) {
      $device->{temp}->{cpu0} = $v;
    }

    if ( $k =~ /^CPU2 Temp/ ) {
      $device->{temp}->{cpu1} = $v;
    }
  }

  # Because Dell and my bad Perl skills.
  # Physical id 0:  +41.0 C  (high = +93.0 C, crit = +103.0 C)
  # Physical id 1:  +52.0 C  (high = +93.0 C, crit = +103.0 C)
  my $cpu_temp = `/usr/bin/sensors | grep Phys`;
  chomp $cpu_temp;

  for (split/^/,$cpu_temp) {
    $_ =~ s/ C.*$//;
    $_ =~ s/\+//;
    my ($cpu, $temp) = split(/:/, $_);
    chomp $cpu;
    chomp $temp;
    $temp =~ s/^\s+|\s+$//g;
    $temp =~ s/\..*$//;

    if ($cpu eq "Physical id 0") {
      $device->{temp}->{cpu0} = $temp;
    }

    if ($cpu eq "Physical id 1") {
      $device->{temp}->{cpu1} = $temp;
    }
  }

  return $device;
}

sub get_smartctl {
  my $disk = shift;

  my $smartctl = `/usr/sbin/smartctl -a /dev/$disk`;
  chomp $smartctl;

  my $devstat = {};

  for ( split /^/, $smartctl ) {
    next unless $_ =~ /:/;
    my ( $k, $v ) = split(/:/, $_);
    chomp $k;
    chomp $v;
    $v =~ s/^\s+|\s+$//g;

    if ( $k =~ /Rotation Rate/ ) {
      $devstat->{rotation} = $v;
    }

    if ( $k =~ /Serial/ ) {
      $devstat->{serial_number} = $v;
    }

    if ( $k =~ /SMART Health Status/ ) {
      $devstat->{health} = $v;
    }

    if ( $k =~ /Current Drive Temperature/ ) {
      $v =~ s/ C$//;
      $devstat->{temp} = $v;
    }
  }

  return $devstat;
}

# This is terrible, even for me.
sub get_lsusb {
  my $devstat = {};

  # XXX This needs to get updated whenever we change USB drives.
  my $device_id = `/usr/bin/lsusb | grep -e Flash -e Kingston`;
  $device_id =~ s/^.*Bus //;
  $device_id =~ s/:.*$//;
  $device_id =~ s/ Device /:/;

  chomp $device_id;

  my $lsusb = `/usr/bin/lsusb -v -s $device_id | grep iSerial`;
  chomp $lsusb;

  my @line = split(/\s+/,$lsusb);
  my $sn = $line[-1];

  my ($hba,$slot) = split(/:/,$device_id);

  $devstat->{serial_number} = $sn;
  $devstat->{hba}  = $hba;
  $devstat->{slot} = $slot;

  return $devstat;
}

sub load_disks {
  my ( $device ) = @_;

  my $output = `/bin/lsblk -ido KNAME,TRAN,SIZE,VENDOR,MODEL > /tmp/lsblk.out`;
  
  open(FILE, "/tmp/lsblk.out") or die "Could not read file: $!";
  while(<FILE>) {
    chomp;
    next if $_ =~ /KNAME/;
  
    # sda sas 93.2G HGST HUSMH8010BSS204
  
    my @line = split(/\s+/,$_);
  
    my $disk   = $line[0];
    my $tran   = $line[1];
    my $size   = $line[2];
    my $vendor = $line[3];
    my $model  = $line[4];

    my $devstat;
    if ($tran eq "usb") {
      $devstat = get_lsusb();
    } else {
      $devstat = get_smartctl($disk);
    }

    if ($size =~ /T/) {
      $size =~ s/T.*$//;
      $size = $size*1000000;
    }

    if ($size =~ /G/) {
      $size =~ s/G.*$//;
      $size = $size*1000;
    }

    unless (defined $devstat->{serial_number}) {
      warn "Could not get serial number for $disk!";
      next;
    }

    my $sn = $devstat->{serial_number};

    $device->{disks}{$sn}{device} = $disk;
    $device->{disks}{$sn}{health} = $devstat->{health} if defined $devstat->{health};
    $device->{disks}{$sn}{temp}   = $devstat->{temp} if defined $devstat->{temp};

    # We might get these from lsusb.
    $device->{disks}{$sn}{hba}    = $devstat->{hba} || 0;
    $device->{disks}{$sn}{slot}   = $devstat->{slot} if defined $devstat->{slot};
  
    $device->{disks}{$sn}{transport} = $tran;
    $device->{disks}{$sn}{size}      = $size;
    $device->{disks}{$sn}{vendor}    = $vendor;
    $device->{disks}{$sn}{model}     = $model;
  }
  
  close FILE;
  
  return $device;
}

sub load_sas3 {
  my ( $device ) = @_;

  my $sas3 = `/var/preflight/bin/sas3ircu 0 DISPLAY > /tmp/sas3.out`;
  
  open(FILE, "/tmp/sas3.out");
  
  my %lines;
  my $slot;
  
  while(<FILE>) {
    if (/^Device is a Hard disk/ .. /Drive Type.*\n$/) {
      chomp;
  
      if ($_ =~ /Slot #/) {
        $slot = $_;
        $slot =~ s/^.*: //;
      }
  
      # The first run won't have $slot defined yet.
      if ($_ =~ /:/ && defined $slot) {
        my ($k, $v) = split(/:/, $_);
  
        $v =~ s/^\s+|\s+$//g;
        $k =~ s/^\s+|\s+$//g;
  
        $lines{$slot}{$k} = $v;
      }
    }
  }
  
  close FILE;

  foreach my $slot (keys %lines) {

    my $sn = $lines{$slot}{'Serial No'};
    $device->{disks}{$sn}{slot}        = $slot;
    $device->{disks}{$sn}{firmware}    = $lines{$slot}{'Firmware Revision'};
    $device->{disks}{$sn}{drive_type}  = $lines{$slot}{'Drive Type'};
    $device->{disks}{$sn}{guid}        = $lines{$slot}{'GUID'};
  }

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

sub load_ipmi_net {
  my ($device) = @_;
  my $output = `/usr/bin/ipmitool lan print 1 > /tmp/ipmi_net.out`;

  open(FILE, "/tmp/ipmi_net.out") or die "Could not read file: $!";

  while(<FILE>) {
    chomp;
    my ($k, $v) = split(/ : /,$_);
    $k =~ s/^\s+|\s+$//g;
    $v =~ s/^\s+|\s+$//g;

    if ( $k eq "IP Address" ) {
      $device->{interfaces}{ipmi1}{ipaddr} = $v;
    }

    if ( $k eq "MAC Address" ) {
      $device->{interfaces}{ipmi1}{mac}    = $v;
    }

    # XXX Could make this smarter by detecting Dell vs SMCI. Or not.
    # racadm getniccfg can tell you if the DRAC link is up, for instance.
    $device->{interfaces}{ipmi1}{product} = "OOB";
    $device->{interfaces}{ipmi1}{vendor}  = "Intel";
  }

  close FILE;

  return $device;
}

my $device = {};

my $ohai = read_ohai();

$device = load_hardware($device);
$device = load_disks($device);
$device = load_sas3($device);
$device = load_interfaces($device, $ohai);
$device = load_ipmi_net($device);
$device = load_device($device, $ohai);
$device = get_temp($device);

p $device;
create_device($device);
