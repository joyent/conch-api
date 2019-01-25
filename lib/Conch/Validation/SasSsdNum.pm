package Conch::Validation::SasSsdNum;

use Mojo::Base 'Conch::Validation';
use v5.20;

has 'name'        => 'sas_ssd_num';
has 'version'     => 2;
has 'category'    => 'DISK';
has 'description' => q( Validate expected number of SAS SSDs );

sub validate {
	my ( $self, $data ) = @_;

	$self->die("Input data must include 'disks' hash")
		unless $data->{disks} && ref( $data->{disks} ) eq 'HASH';

	my $hw_profile = $self->hardware_product_profile;

	my @disks_with_drive_type =
		grep { $_->{drive_type} } ( values $data->{disks}->%* );

	my $sas_ssd_count = grep {
		fc( $_->{drive_type} ) eq fc('SAS_SSD')
	} @disks_with_drive_type;

	my $sas_ssd_want = $hw_profile->sas_ssd_num || 0;

	$self->register_result(
		expected => $sas_ssd_want,
		got      => $sas_ssd_count,
	);

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
