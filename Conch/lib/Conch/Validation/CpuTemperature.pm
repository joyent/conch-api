package Conch::Validation::CpuTemperature;

use Mojo::Base 'Conch::Validation';

has 'name'        => 'cpu_temperature';
has 'version'     => 1;
has 'category'    => 'CPU';
has 'description' => q(
Validate the reported CPU temperatures are less than the maximum in the
hardware product profile
);

has schema => sub {
	{
		temp => {
			type       => 'object',
			required => [ 'cpu0', 'cpu1' ],
			properties => {
				cpu0 => { type => 'number' },
				cpu1 => { type => 'number' }
			}
		}
	};
};

sub validate {
	my ( $self, $data ) = @_;

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
