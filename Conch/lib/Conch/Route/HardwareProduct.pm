=pod

=head1 NAME

Conch::Route::HardwareProduct

=head1 METHODS

=cut

package Conch::Route::HardwareProduct;
use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT = qw(
	hardware_product_routes
);


=head2 hardware_product_routes

Sets up the routes for /hardware_product

=cut

sub hardware_product_routes {
	my $r = shift;

	$r->get('/hardware_product')->to('hardware_product#list');
	$r->get('/hardware_product/:id')->to('hardware_product#get');

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

