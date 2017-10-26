package Conch::Control::Relay;

use strict;
use Log::Any '$log';
use Dancer2::Plugin::Passphrase;
use Conch::Control::User;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( register_relay list_user_relays connect_user_relay
  device_relay_connect
);

sub list_user_relays {
  my ( $schema, $user_name, $interval ) = @_;

  my $user_id = user_id_by_name( $schema, $user_name );
  my $user_relays = $schema->resultset('UserRelayConnection')->search(
    {
      user_id   => $user_id,
      last_seen => { '>' => \"NOW() - INTERVAL '1 week'" }
    }
  );

  my @relays;
  if ($interval) {
    @relays = $schema->resultset('Relay')->search(
      {
        id      => { -in => $user_relays->get_column('relay_id')->as_query },
        updated => { '>' => \"NOW() - INTERVAL '$interval minutes'" },
        deactivated => { '=', undef }
      }
    )->all;
  }
  else {
    @relays = $schema->resultset('Relay')->search(
      {
        id => { -in => $user_relays->get_column('relay_id')->as_query },
        deactivated => { '=', undef }
      }
    )->all;
  }

  my @relay_ids = map { $_->id } @relays;
  my @relay_locations = $schema->resultset('RelayLocation')
    ->search( { relay_id => { -in => \@relay_ids } } )->all;
  my $relay_locations = {};
  for my $loc (@relay_locations) {
    $relay_locations->{ $loc->relay_id } = {
      rack_id   => $loc->rack_id,
      rack_name => $loc->rack_name,
      room_name => $loc->room_name,
      role_name => $loc->role_name
    };
  }

  my @res;
  for my $relay (@relays) {
    my @devices = $schema->resultset('RelayDevices')
      ->search( {}, { bind => [ $relay->id ] } )->all;

    my $relay_res = { $relay->get_columns };
    @devices = map {
      { $_->get_columns }
    } @devices;

    $relay_res->{devices}  = \@devices;
    $relay_res->{location} = $relay_locations->{ $relay->id };
    push @res, $relay_res;
  }
  return @res;

}

sub register_relay {
  my ( $schema, $serial, $client_ip, $attrib ) = @_;

  # XXX $client_ip is where the request comes from, which is probably a NAT.
  # XXX We should store that! But the actual Relay IP is in the attrib hash.

  $log->info("Registering relay device $serial");

  my $relay = $schema->resultset('Relay')->update_or_create(
    {
      id       => $serial,
      ipaddr   => $attrib->{ipaddr} || undef,
      version  => $attrib->{version},
      ssh_port => $attrib->{ssh_port},
      updated  => \'NOW()'
    }
  );

  unless ( $relay->in_storage ) {
    $log->warning("Could not register relay device $serial");
    return undef;
  }
}

# Associate relay with a user
sub connect_user_relay {
  my ( $schema, $user_id, $relay_id ) = @_;

  # 'first_seen' column will only be written on create. It should remain
  # untouched on updates
  $schema->resultset('UserRelayConnection')->update_or_create(
    {
      user_id   => $user_id,
      relay_id  => $relay_id,
      last_seen => \'NOW()'
    }
  );
}

# Associate relay with a device
sub device_relay_connect {
  my ( $schema, $device_id, $relay_id ) = @_;

  # 'first_seen' column will only be written on create. It should remain
  # untouched on updates
  $schema->resultset('DeviceRelayConnection')->update_or_create(
    {
      device_id => $device_id,
      relay_id  => $relay_id,
      last_seen => \'NOW()'
    }
  );
}

1;
