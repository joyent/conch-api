package Conch::Validation::DimmMap;

use Mojo::Base 'Conch::Validation';

has 'name'        => 'dimm_map';
has 'version'     => 1;
has 'category'    => 'RAM';
has 'description' => 'Identify any missing or misbehaving DIMMs';

sub validate {
	my ( $self, $data ) = @_;

	my $dimms   = $data->{dimms};
	my $hw_spec = $self->hardware_product_specification;
	my $dimm_sepc = $hw_spec->{memory}->{dimms};

	#$self->register_result(
	#	expected => 
	#	got      => 
		#message  => $message,
		#hint     => "",
	#);
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
