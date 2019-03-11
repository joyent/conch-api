package Conch::Validation::SwitchPeers;

use Mojo::Base 'Conch::Validation';
use List::Util 'first';

use constant name        => 'switch_peers';
use constant version     => 1;
use constant category    => 'NET';
use constant description => q(
Validate the number of peer switches, the number of peer ports, and the
expected peer port according to the rack layout
);

sub validate {
	my ( $self, $data ) = @_;

	unless($data->{interfaces}) {
		$self->die("Missing 'interfaces' property");
	}

	my @eth_nics =
		map { $data->{interfaces}->{$_} }
		grep { $_ =~ /eth/ } ( keys $data->{interfaces}->%* );

	# We assume that all eth_nics are peered with the same device right now.
	# This should eventually also validate if we are peered to the right
	# place.

	my $peer_vendor;
	for my $e (@eth_nics) {
		if($e->{peer_vendor}) {
			$peer_vendor = $e->{peer_vendor};

		} elsif($e->{peer_descr}) {
			# This is fragile because it depends on the format of the text string in
			# peer_descr
			# Example: "peer_descr": "Arista Networks EOS version 4.20.7M running on an Arista Networks $serial",
			# We're extracting "Arista" from that string. Should it ever change, this
			# code will break.

			# Eventually, this normalization will be done on the edge and this
			# block can be removed.
			# [2018-07-11 sungo]
			$peer_vendor = $e->{peer_descr};
			$peer_vendor =~ s/\s.+$//;
		}
		last if $peer_vendor;
	}

	my @rack_unit_starts = map $_->{rack_unit_start},
		$self->device_location
			->search_related('rack')
			->search_related('rack_layouts', undef, {
				columns => { rack_unit_start => 'rack_layouts.rack_unit_start' },
				order_by => 'rack_unit_start',
			})
			->hri->all;

	my @peer_ports = $self->_calculate_switch_peer_ports(
		$self->device_location->rack_unit_start,
		\@rack_unit_starts,
		$peer_vendor,
	);

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
	my ( $self, $rack_unit_start, $rack_slots, $peer_vendor ) = @_;

	# Note this failure is no longer possible given the foreign key constraint added in v2.19 (a4549d4a)
	my $rack_index = first { $rack_slots->[$_] == $rack_unit_start } 0 .. $rack_slots->$#*;

	defined $rack_index
		or $self->die('Device assigned to rack unit not in rack layout');

	my $first_port = 1 + $rack_index;

	if ($peer_vendor) {
		if ($peer_vendor eq "Dell") {
			# offset of 19 is standard for all Dell deployments, including 62U racks
			my $second_port = $first_port + 19;
			return ( "1/$first_port", "1/$second_port" );
		} elsif ($peer_vendor eq "Arista") {
			# offset of 24 is standard for all Arista deployments, including 62U racks
			my $second_port = $first_port + 24;
			return ( "Ethernet$first_port", "Ethernet$second_port" );
		}
	}

	# Handle reports that lack peer vendor data
	my $second_port = $first_port + 19;
	return ( "1/$first_port", "1/$second_port" );

}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
