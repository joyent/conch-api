package Conch::Validation::BiosFirmwareVersion;

use Mojo::Base 'Conch::Validation';

has 'name'        => 'bios_firmware_version';
has 'version'     => 1;
has 'category'    => 'BIOS';
has 'description' => q(
Validate the reported BIOS firmware version matches the hardware product
profile
);

has schema => sub {
	{
		bios_version => {
			type => 'string',
		}
	};
};

sub validate {
	my ( $self, $data ) = @_;

	my $hw_profile = $self->hardware_product_profile;

	$self->register_result(
		expected => $hw_profile->bios_firmware,
		got      => $data->{bios_version}
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
