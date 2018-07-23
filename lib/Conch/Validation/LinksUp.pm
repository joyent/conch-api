package Conch::Validation::LinksUp;

use Mojo::Base 'Conch::Validation';

has 'name'        => 'links_up';
has 'version'     => 1;
has 'category'    => 'NET';
has 'description' => q(
Validate that there are at least 4 NICs in the 'up' state
);

sub validate {
	my ( $self, $data ) = @_;

	$self->die("Input data must include 'interfaces' hash")
		unless $data->{interfaces} && ref( $data->{interfaces} ) eq 'HASH';

	my $links_up = 0;
	while ( my ( $name, $nic ) = each $data->{interfaces}->%* ) {
		next if $name eq 'impi1';
		$links_up++ if ($nic->{state} && $nic->{state} eq 'up');
	}

	$self->register_result(
		expected => 4,
		cmp      => '>=',
		got      => $links_up
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
