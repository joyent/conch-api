package Conch::Validation::SwitchPeers;

use Mojo::Base 'Conch::Validation';
use List::Util 'first';

has 'name'        => 'switch_peers';
has 'version'     => 1;
has 'category'    => 'NET';
has 'description' => q(
Validate the number of peer switches, the number of peer ports, and the
expected peer port according to the rack layout
);

has schema => sub {
	{
		interfaces => {
			type => 'object',
		}
	};
};

sub validate {
	my ( $self, $data ) = @_;

	my $device_location = $self->device_location;

	my $rack_slots = $device_location->datacenter_rack->slots;

	my @peer_ports =
		$self->_calculate_switch_peer_ports( $device_location->rack_unit,
		$rack_slots );

	my @eth_nics =
		map { $data->{interfaces}->{$_} }
		grep { $_ =~ /eth/ } ( keys $data->{interfaces}->%* );

	my $switch_peers = {};

	for my $nic (@eth_nics) {
		my $peer_port = $nic->{peer_port};
		my $peer_name = $nic->{peer_mac};

		# skip if the link doesn't have a peer configured
		next unless $peer_port;

		$switch_peers->{$peer_name}->{$peer_port} = 1;

		$self->register_result(
			expected     => [@peer_ports],
			got          => $peer_port,
			cmp          => 'oneOf',
			component_id => $nic->{nic},
			name         => 'peer_ports'
		);

	}

	# Validate the number of switches
	my $num_switches = keys %{$switch_peers};

	$self->register_result(
		expected => 2,
		got      => $num_switches,
		name     => 'num_switches'
	);

	# Validate the number of ports per switch
	# Since $switch_peer is a hashref, duplicates will be detected as only having
	# 1 port
	for my $switch_name ( keys %{$switch_peers} ) {
		my $num_ports = keys %{ $switch_peers->{$switch_name} };

		$self->register_result(
			expected => 2,
			got      => $num_ports,
			name     => 'num_ports'
		);
	}
}

sub _calculate_switch_peer_ports {
	my ( $self, $rack_unit, $rack_slots ) = @_;
	my $rack_index =
		first { $rack_slots->[$_] == $rack_unit } 0 .. $rack_slots->$#*;
	defined $rack_index
		or $self->die('Device assigned to rack unit not in rack layout');

	my $first_port = 1 + $rack_index;

	# offset of 19 is standard for all deployments, including 62U racks
	my $second_port = $first_port + 19;

	return ( "1/$first_port", "1/$second_port" );
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
