package Conch::Validation::DeviceProductName;

use Mojo::Base 'Conch::Validation';

has name        => 'product_name';
has version     => 1;
has 'category'  => 'BIOS';
has description => q(
Valdidate reported product name matches product name expected in rack layout
);

has schema => sub {
	{
		product_name => {
			type => 'string'
		}
	}

};

sub validate {
	my ( $self, $data ) = @_;
	if(
		($data->{product_name} =~ /^Joyent-Compute/) or
		($data->{product_name} =~ /^Joyent-Storage/)
	) {
		$self->register_result(
			expected => $self->hardware_legacy_product_name,
			got      => $data->{product_name},
		);
	} else {
		$self->register_result(
			expected => $self->hardware_product_generation,
			got      => $data->{product_name},
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
