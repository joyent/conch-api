package Conch::Controller::Validate::Network;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use Data::Printer;

=head1 NAME

Conch::Controller::Validate::Network - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Conch::Controller::Validate::Network in Validate::Network.');

    $c->forward('links');
    $c->forward('wiremap');
}

sub links : Private {
  my ( $self, $c ) = @_;

  my $device_id = $c->req->data->{serial_number};
  $c->log->debug("$device_id: Validating network links");

  my $device_nics = $c->model('DB::DeviceNic')->search({
    device_id => $device_id
  });

  my $device_spec = $c->model('DB::DeviceSpec')->search({
    device_id => $device_id
  })->single;

  my $hw_profile = $c->model('DB::HardwareProductProfile')->search({
    id => $device_spec->product_id
  })->single;

  my $links_up;
  while ( my $iface = $device_nics->next ) {
    next if $iface->iface_name eq "ipmi1";
    my $nic_state = $c->model('DB::DeviceNicState')->search({
      mac => $iface->mac,
    })->single;

    # XXX Once we have a wiremap, we should go off the wiremap, and this naive check.
    # We expect to have 4 links up.
    $links_up++ if $nic_state->state eq "up";
  }

  $c->log->debug("$device_id: validating links_up");
  my $nic_state_msg;
  my $nic_state_status;

  my $nic_state_log = "Has = $links_up, Want = 4";
  if ( $links_up < 4 ) {
    $nic_state_msg = "$device_id: CRITICAL: links_up: $nic_state_log";
    $nic_state_status = 0;
   } else {
     $nic_state_msg = "$device_id: OK: links_up: $nic_state_log";
     $nic_state_status = 1;
   }

   $c->log->debug($nic_state_msg);

   my $device_validate = $c->model('DB::DeviceValidate')->update_or_create({
     device_id       => $device_id,
     component_type  => "NET",
     component_name  => "links_up",
     log             => $nic_state_msg,
     status          => $nic_state_status,
   });
}

sub wiremap : Private {
  my ( $self, $c ) = @_;

  # peer_switch         text,       --- from LLDP
  # peer_port           text,       --- from LLDP
  # want_switch         text,       --- from wiremap spec
  # want_port           text,       --- from wiremap spec

  my $device_id = $c->req->data->{serial_number};
  $c->log->debug("$device_id: Validating network links");

  my $device_nics = $c->model('DB::DeviceNic')->search({
    device_id => $device_id
  });

  while ( my $iface = $device_nics->next ) {
    next if $iface->iface_name eq "ipmi1";
    my $nic_state = $c->model('DB::DeviceNicState')->search({
      mac => $iface->mac,
    })->single;

    my $nic_neighbor = $c->model('DB::DeviceNeighbor')->search({
      mac => $iface->mac,
    })->single;

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
      $c->log->debug("$device_id: CRITICAL: Wrong peer: $nic_peer_log");
    } else {
      $nic_peer_status = 1;
      $c->log->debug("$device_id: OK: Correct peer: $nic_peer_log");
    }

    my $nic_peer_record = $c->model('DB::DeviceValidate')->update_or_create({
      device_id       => $device_id,
      component_type  => "NET",
      component_name  => $iface->mac . "_peer",
      log             => $nic_peer_log,
      status          => $nic_peer_status
    });  
  }
  
}

=encoding utf8

=head1 AUTHOR

Super-User

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
