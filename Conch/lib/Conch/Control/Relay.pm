package Conch::Control::Relay;

use strict;
use Log::Report;
use Log::Report::DBIC::Profiler;
use Dancer2::Plugin::Passphrase;
use Conch::Control::User;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( register_relay list_relays associate_relay);

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
  my ($schema, $serial, $ip, $attrib) = @_;

  info "Registering relay device $serial";

  my $relay = $schema->resultset('Relay')->update_or_create({
    id        => $serial,
    ipaddr    => $ip,
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
sub associate_relay {
  my ($schema, $user_name, $relay_id) = @_;
  my $user_id = lookup_user_by_name($schema, $user_name)->id;

  # 'first_seen' column will only be written on create. It should remain
  # untouched on updates
  $schema->resultset('RelayUser')->update_or_create({
    user_id   => $user_id,
    relay_id  => $relay_id,
    last_seen => \'NOW()'
  });
};

1;
