package Conch::Route::HardwareProduct;
use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT_OK = qw(
    hardware_product_routes
);

=pod

=head1 NAME

Conch::Route::HardwareProduct

=head1 METHODS

=head2 hardware_product_routes

Sets up the routes for /hardware_product:

    GET /hardware_product
    GET /hardware_product/:hardware_product_id

=cut

sub hardware_product_routes {
    my $hardware_product = shift; # secured, under /hardware_produt

    # GET /hardware_product
    $hardware_product->get('/')->to('hardware_product#list');

    # GET /hardware_product/:hardware_product_id
    $hardware_product->get('/:hardware_product_id')->to('hardware_product#get');
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
# vim: set ts=4 sts=4 sw=4 et :
