package Conch::Validation::SasSsdNum;

use Mojo::Base 'Conch::Validation';
use v5.20;

has 'name'        => 'sas_ssd_num';
has 'version'     => 1;
has 'description' => q( Validate expected number of SSDs );

sub validate {
	my ( $self, $data ) = @_;

	$self->die("Input data must include 'disks' hash")
		unless $data->{disks} && ref( $data->{disks} ) eq 'HASH';

	my $hw_profile = $self->hardware_product_profile;

	my $ssd_num = grep {
		     fc( $_->{drive_type} ) eq fc('SAS_SSD')
			|| fc( $_->{drive_type} ) eq fc('SATA_SSD')
	} ( values $data->{disks}->%* );

	my $ssd_want = $hw_profile->ssd_num;

	# Joyent-Compute-Platform-3302 special case.  HCs can have 8 or 16 SSD and
	# there's no other identifier. Here, we want to avoid missing
	# failed/missing disks, so we jump through a couple extra hoops.
	if ( $self->hardware_product_name eq "Joyent-Compute-Platform-3302" ) {
		if ( $ssd_num <= 8 ) { $ssd_want = 8; }
		if ( $ssd_num > 8 )  { $ssd_want = 16; }
	}

	$self->register_result(
		expected       => $ssd_want,
		got            => $ssd_num,
		component_type => 'DISK'
	);

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
