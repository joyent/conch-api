package Conch::Control::Device::Network;

use strict;
use Log::Report;
use JSON::XS;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( validate_links validate_wiremap );

sub validate_links {
  my ($schema, $device, $report_id) = @_;

  my $device_id = $device->id;
  trace("$device_id: report $report_id: Validating network links");

  my $device_nics = $device->device_nics;

  my $links_up;
  while ( my $iface = $device_nics->next ) {
    next if $iface->iface_name eq "ipmi1";
    my $nic_state = $iface->device_nic_state;

    # XXX Once we have a wiremap, we should go off the wiremap, and this naive
    # check.  We expect to have 4 links up.
    $links_up++ if $nic_state->state eq "up";
  }

  trace("$device_id: report $report_id: validating links_up");
  my $nic_state_msg;
  my $nic_state_status;

  my $nic_state_log = "Has = $links_up, Want = 4";
  if ( $links_up < 4 ) {
    $nic_state_msg = "$device_id: report $report_id: CRITICAL: links_up: $nic_state_log";
    mistake $nic_state_msg;
    $nic_state_status = 0;
   } else {
     $nic_state_msg = "$device_id: report $report_id: OK: links_up: $nic_state_log";
     trace $nic_state_msg;
     $nic_state_status = 1;
   }

   $schema->resultset('DeviceValidate')->update_or_create({
     device_id       => $device_id,
     report_id       => $report_id,
     validation      => encode_json({
       component_type  => "NET",
       component_name  => "links_up",
       log             => $nic_state_msg,
       status          => $nic_state_status,
     })
   });
}

sub switch_peer_ports {
  my $rack_location = shift;
  my $role = $rack_location->rack->role;
  my $ru = $rack_location->rack_unit;
  my $case = {
    'TRITON'     => sub { port_numbers(2, $ru) },
    # upper two units are 2U racks
    'MANTA'      => sub { $ru < 34 ? port_numbers(4,$ru) : port_numbers(2, $ru) },
    'MANTA_TALL' => sub { port_numbers(4, $ru) }
  };
  return $case->{$role->name}->();
}

# Calculate the switch port numbers for a rack unit and size. Provides a hash
sub port_numbers {
  my $size = shift;
  my $rack_unit = shift;
  my $first_port = int(($rack_unit- 1) / $size) + 1;
  my $second_port = $first_port + 19;
  return { "1/$first_port" => 1, "1/$second_port" => 1 };
}


sub validate_wiremap {
  my ($schema, $device, $report_id) = @_;

  my $device_id = $device->id;
  trace("$device_id: report $report_id: Validating network links");

  my @device_nics = $device->device_nics->all;

  trace("$device_id: Validating network switch peers");

  my @eth_nics = grep {$_->iface_name =~ /eth/} @device_nics;

  my $switch_peer_ports = switch_peer_ports($device->device_location);
  my @peer_ports = keys %{$switch_peer_ports};

  for my $nic (@eth_nics) {
    my $nic_neighbor = $nic->device_neighbor;
    my $peer_port = $nic_neighbor->peer_port;

    # skip if the link doesn't have a peer configured
    next unless $peer_port;

    my $nic_peer_log;
    my $nic_peer_status;
    my $nic_peer_msg = "Interface ".$nic->iface_name." Has $peer_port, Needs either of @peer_ports";
    if ($switch_peer_ports->{$peer_port}) {
      $nic_peer_log = "$device_id: report $report_id: OK: Correct peer: $nic_peer_msg";
      $nic_peer_status = 1;
      info $nic_peer_log;
    }
    else {
      $nic_peer_log ="$device_id: report $report_id: CRITICAL: Wrong peer port: $nic_peer_msg";
      $nic_peer_status = 0;
      mistake $nic_peer_log;
    }

    $schema->resultset('DeviceValidate')->update_or_create({
      device_id       => $device_id,
      report_id       => $report_id,
      validation      => encode_json({
          component_type  => "NET",
          component_name  => $nic->mac . "_peer",
          log             => $nic_peer_msg,
          status          => $nic_peer_status
        })
    });
  }

}

1;
