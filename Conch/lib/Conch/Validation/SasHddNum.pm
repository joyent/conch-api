package Conch::Validation::SasHddNum;

use Mojo::Base 'Conch::Validation';
use v5.20;

has 'name'        => 'sas_hdd_num';
has 'version'     => 1;
has 'category'    => 'DISK';
has 'description' => q( Validate expected number of SAS HDDs );

sub validate {
	my ( $self, $data ) = @_;

	$self->die("Input data must include 'disks' hash")
		unless $data->{disks} && ref( $data->{disks} ) eq 'HASH';

	my $hw_profile = $self->hardware_product_profile;

	my $sas_hdd_num = grep { fc( $_->{drive_type} ) eq fc('SAS_HDD') }
		( values $data->{disks}->%* );

	$self->register_result(
		expected => $hw_profile->sas_num,
		got      => $sas_hdd_num,
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
