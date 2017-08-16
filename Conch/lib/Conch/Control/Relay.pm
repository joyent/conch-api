package Conch::Control::Relay;

use strict;
use Log::Report;
use Log::Report::DBIC::Profiler;
use Dancer2::Plugin::Passphrase;
use Conch::Control::User;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( register_relay list_relays connect_user_relay
                  device_relay_connect
                );

sub list_relays {
  my ($schema, $interval) = @_;

  my @relays_rs;
  if ($interval) {
    @relays_rs = $schema->resultset('Relay')->search({
      updated => { '>' => \"NOW() - INTERVAL '$interval minutes'" }
    })->all;
  } else {
    @relays_rs = $schema->resultset('Relay')->search({})->all;
  }

  my $relays = {};

  foreach my $r (@relays_rs) {
    my $serial = $r->id;
    $relays->{ $serial }{ ssh_port } = $r->ssh_port;
    $relays->{ $serial }{ version }  = $r->version;
  }

  return $relays;
}

sub register_relay {
  my ($schema, $serial, $client_ip, $attrib) = @_;

  # XXX $client_ip is where the request comes from, which is probably a NAT.
  # XXX We should store that! But the actual Relay IP is in the attrib hash.

  info "Registering relay device $serial";

  my $relay = $schema->resultset('Relay')->update_or_create({
    id        => $serial,
    ipaddr    => $attrib->{ipaddr} || undef,
    version   => $attrib->{version},
    ssh_port  => $attrib->{ssh_port},
    updated   => \'NOW()'
  });

  unless ($relay->in_storage) {
    warning "Could not register relay device $serial";
    return undef;
  }
}

# Associate relay with a user
sub connect_user_relay {
  my ($schema, $user_name, $relay_id) = @_;
  my $user_id = lookup_user_by_name($schema, $user_name)->id;

  # 'first_seen' column will only be written on create. It should remain
  # untouched on updates
  $schema->resultset('UserRelayConnection')->update_or_create({
    user_id   => $user_id,
    relay_id  => $relay_id,
    last_seen => \'NOW()'
  });
};

# Associate relay with a device
sub device_relay_connect {
  my ($schema, $device_id, $relay_id) = @_;

  # 'first_seen' column will only be written on create. It should remain
  # untouched on updates
  $schema->resultset('DeviceRelayConnection')->update_or_create({
    device_id   => $device_id,
    relay_id  => $relay_id,
    last_seen => \'NOW()'
  });
}

1;
