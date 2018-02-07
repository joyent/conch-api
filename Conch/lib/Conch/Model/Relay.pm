=pod

=head1 NAME

Conch::Model::Relay

=head1 METHODS

=cut
package Conch::Model::Relay;
use Mojo::Base -base, -signatures;

use Conch::Class::Relay;
use Conch::Time;

use Try::Tiny;

has 'pg';

=head2 create

Create a new Relay.

=cut
sub create ( $self, $serial, $version, $ipaddr, $ssh_port, $alias,
	$ip_origin = undef )
{
	my $ret;
	try {
		$ret = $self->pg->db->query(
			q{
      INSERT INTO relay
        ( id, version, ipaddr, ssh_port, updated )
      VALUES
        ( ?, ?, ?, ?, ? )
      ON CONFLICT (id) DO UPDATE
      SET id = excluded.id,
          version = excluded.version,
          ipaddr = excluded.ipaddr,
          ssh_port = excluded.ssh_port,
          updated = excluded.updated
    },
			$serial,
			$version,
			$ipaddr,
			$ssh_port,
			'NOW()'
		)->rows;
	};
	return $ret;
}

=head2 lookup

Look up a relay by ID.

=cut
sub lookup ( $self, $relay_id ) {
	return $self->pg->db->select( 'relay', undef, { id => $relay_id } )->hash;
}

=head2 connect_user_relay

Associate relay with a user.

=cut
sub connect_user_relay ( $self, $user_id, $relay_id ) {
	my $ret;
	try {
		# 'first_seen' column will only be written on create. It should remain
		# unchanged on updates
		$ret = $self->pg->db->query(
			q{
        INSERT INTO user_relay_connection
          ( user_id, relay_id, last_seen )
        VALUES
          ( ?, ?, ? )
        ON CONFLICT (user_id, relay_id) DO UPDATE
        SET user_id = excluded.user_id,
            relay_id = excluded.relay_id,
            last_seen = excluded.last_seen
      }, $user_id, $relay_id, 'NOW()'
		)->rows;
	};
	return $ret;
}

=head2 connect_device_relay

Associate relay with a device

=cut
sub connect_device_relay ( $self, $device_id, $relay_id ) {
	my $ret;
	try {
		# 'first_seen' column will only be written on create. It should remain
		# unchanged on updates
		$ret = $self->pg->db->query(
			q{
        INSERT INTO device_relay_connection
          ( device_id, relay_id, last_seen )
        VALUES
          ( ?, ?, ? )
        ON CONFLICT (device_id, relay_id) DO UPDATE
        SET device_id = excluded.device_id,
            relay_id = excluded.relay_id,
            last_seen = excluded.last_seen
      }, $device_id, $relay_id, 'NOW()'
		)->rows;
	};
	return $ret;
}


=head2 list

Provide a list of all relays in the database as Class::Relay objects

=cut

sub list ( $self ) {
	my @relays;
	try {
		for my $r ($self->pg->db->select('relay')->hashes->@*) {
			$r->{created} = Conch::Time->new($r->{created}) if $r->{created};
			$r->{updated} = Conch::Time->new($r->{updated}) if $r->{updated};
			push @relays, Conch::Class::Relay->new($r);
		}
	};
	return @relays;
}

1;


__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

