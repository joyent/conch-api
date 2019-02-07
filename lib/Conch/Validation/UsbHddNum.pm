package Conch::Validation::UsbHddNum;

use Mojo::Base 'Conch::Validation';
use v5.20;

use constant name        => 'usb_hdd_num';
use constant version     => 1;
use constant category    => 'DISK';
use constant description => q( Validate expected number of reported USB HDDs );

sub validate {
	my ( $self, $data ) = @_;

	$self->die("Input data must include 'disks' hash")
		unless $data->{disks} && ref( $data->{disks} ) eq 'HASH';

	my $hw_profile = $self->hardware_product_profile;

	my $usb_num =
		grep { fc( $_->{transport} ) eq fc('usb') } ( values $data->{disks}->%* );

	$self->register_result(
		expected => $hw_profile->usb_num || 0,
		got      => $usb_num,
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
