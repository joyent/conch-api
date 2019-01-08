package Conch::Validation::CpuTemperature;

use Mojo::Base 'Conch::Validation';

use constant name        => 'cpu_temperature';
use constant version     => 1;
use constant category    => 'CPU';
use constant description => q(
Validate the reported CPU temperatures are less than the maximum in the
hardware product profile
);

sub validate {
	my ( $self, $data ) = @_;

	unless($data->{temp}) {
		$self->die("Missing 'temp' field");
	}

	unless($data->{temp}->{cpu0} and $data->{temp}->{cpu1}) {
		$self->die("'cpu0' and 'cpu1' entries are required for 'temp'");
	}

	# Value from device_validate_criteria in legacy validations
	my $MAX_TEMP = 70;

	for my $cpu (qw/cpu0 cpu1/) {
		$self->register_result(
			type     => 'CPU',
			expected => $MAX_TEMP,
			cmp      => '<',
			got      => $data->{temp}->{$cpu}
		);
	}

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
