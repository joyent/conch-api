package Conch::Validation::RamTotal;

use Mojo::Base 'Conch::Validation';

has 'name'        => 'ram_total';
has 'version'     => 1;
has 'category'    => 'RAM';
has 'description' => q(
Validate the reported RAM match the hardware product profile
);

has schema => sub {
	{
		memory   => {
			type       => 'object',
			required => ['total'],
			properties => {
				total    => { type => 'integer' }
			}
		}
	};
};

sub validate {
	my ( $self, $data ) = @_;

	my $hw_profile = $self->hardware_product_profile;

	my $ram_total = $data->{memory}->{total};
	my $ram_want  = $hw_profile->ram_total;

	$self->register_result(
		expected => $ram_want,
		got      => $ram_total,
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
