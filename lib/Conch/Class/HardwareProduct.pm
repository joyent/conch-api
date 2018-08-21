=pod

=head1 NAME

Conch::Class::HardwareProduct

=head1 METHODS

=cut

package Conch::Class::HardwareProduct;
use Mojo::Base -base, -signatures;

=head2 id

=head2 name

=head2 alias

=head2 prefix

=head2 vendor

=head2 profile

=head2 specification

=head2 sku

=head2 generation_name

=head2 legacy_product_name

=cut

has [
	qw(
		id
		alias
		generation_name
		legacy_product_name
		name
		prefix
		profile
		sku
		specification
		vendor
	)
];

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
