package Conch::Control::Device::Network;

use strict;
use Log::Report;

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
     component_type  => "NET",
     component_name  => "links_up",
     log             => $nic_state_msg,
     status          => $nic_state_status,
   });
}

sub validate_wiremap {
  my ($schema, $device, $report_id) = @_;

  my $device_id = $device->id;
  trace("$device_id: report $report_id: Validating network links");

  my $device_nics = $device->device_nics;

  # peer_switch         text,       --- from LLDP
  # peer_port           text,       --- from LLDP
  # want_switch         text,       --- from wiremap spec
  # want_port           text,       --- from wiremap spec

  trace("$device_id: Validating network links");

  while ( my $iface = $device_nics->next ) {
    next if $iface->iface_name eq "ipmi1";

    my $nic_state = $iface->device_nic_state;
    my $nic_neighbor = $iface->device_neighbor;

    my $nic_peer_status;

    # If we don't have a wiremap entry _or_ LLDP for a port, skip it. Who cares.
    next unless (defined $nic_neighbor->peer_switch || defined $nic_neighbor->want_switch);

    my $want_switch = "?";
    my $want_port   = "?";

    my $peer_switch = "?";
    my $peer_port   = "?";

    if ( defined $nic_neighbor->want_switch ) {
      $want_switch = $nic_neighbor->want_switch;
    }
    if ( defined $nic_neighbor->want_port ) {
      $want_port = $nic_neighbor->want_port;
    }

    if ( defined $nic_neighbor->peer_switch ) {
      $peer_switch = $nic_neighbor->peer_switch;
    }
    if ( defined $nic_neighbor->peer_port ) {
      $peer_port = $nic_neighbor->peer_port;
    }

    my $has_sup  = "$peer_switch:$peer_port";
    my $want_sup = "$want_switch:$want_port";

    my $nic_peer_log = $iface->mac . ": Has = $has_sup, Want = $want_sup, Link = " . $nic_state->state;

    if ( $has_sup ne $want_sup ) {
      $nic_peer_status = 0;
      mistake("$device_id: report $report_id: CRITICAL: Wrong peer: $nic_peer_log");
    } else {
      $nic_peer_status = 1;
      trace("$device_id: report $report_id: OK: Correct peer: $nic_peer_log");
    }

    $schema->resultset('DeviceValidate')->update_or_create({
      device_id       => $device_id,
      report_id       => $report_id,
      component_type  => "NET",
      component_name  => $iface->mac . "_peer",
      log             => $nic_peer_log,
      status          => $nic_peer_status
    });
  }

}

1;
