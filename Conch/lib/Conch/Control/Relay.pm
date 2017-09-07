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

  my @relays;
  if ($interval) {
    @relays = $schema->resultset('Relay')->search({
      updated => { '>' => \"NOW() - INTERVAL '$interval minutes'" },
      deactivated => { '=', undef }
    })->all;
  } else {
    @relays = $schema->resultset('Relay')->search({
      deactivated => { '=', undef }
    })->all;
  }

  my @res;
  for my $relay (@relays) {
    my @devices = $schema->resultset('RelayDevices')->
      search({}, { bind => [$relay->id] })->all;
    my $location = $schema->resultset('RelayLocation')->
      search({}, { bind => [$relay->id] })->single;

    my $relay_res = {$relay->get_columns};
    @devices = map { {$_->get_columns} } @devices;

    $relay_res->{devices} = \@devices;
    $relay_res->{location} = $location ? {$location->get_columns} : undef;
    push @res, $relay_res;
  }
  return @res;

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
    device_id  => $device_id,
    relay_id  => $relay_id,
    last_seen => \'NOW()'
  });
}

1;
