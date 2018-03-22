package Conch::Validation::CpuCount;

use Mojo::Base 'Conch::Validation';

has 'name'        => 'cpu_count';
has 'version'     => 1;
has 'category'    => 'CPU';
has 'description' => q(
Validate the reported number of CPUs match the hardware product profile
);

has schema => sub {
	{
		required  => ['processor'],
		processor => {
			type       => 'object',
			properties => {
				required => ['count'],
				count    => { type => 'integer' }
			}
		}
	};
};

sub validate {
	my ( $self, $data ) = @_;

	my $hw_profile = $self->hardware_product_profile;

	$self->register_result(
		expected => $hw_profile->cpu_num,
		got      => $data->{processor}->{count},
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
