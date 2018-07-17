package Conch::Validation::DiskTemperature;

use Mojo::Base 'Conch::Validation';
use v5.20;

has 'name'        => 'disk_temperature';
has 'version'     => 1;
has 'category'    => 'DISK';
has 'description' => q(
Validate the reported disk temperatures are under the maximum threshold
);

sub validate {
	my ( $self, $data ) = @_;

	$self->die("Input data must include 'disks' hash")
		unless $data->{disks} && ref( $data->{disks} ) eq 'HASH';

	$self->die("'disks' hash is empty")
		unless $data->{disks}->%*;

	while ( my ( $disk_sn, $disk ) = ( each $data->{disks}->%* ) ) {
		next if !$disk->{transport} || fc( $disk->{transport} ) eq fc('usb');

		$self->fail("No temperature reported for disk $disk_sn") && next
			unless defined( $disk->{temp} );

		# from legacy validation
		my $MAX_TEMP = 51;
		$MAX_TEMP = 60 if $disk->{drive_type} eq 'SAS_HDD';

		$self->register_result(
			expected     => $MAX_TEMP,
			got          => $disk->{temp},
			cmp          => '<',
			component_id => $disk_sn,
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
