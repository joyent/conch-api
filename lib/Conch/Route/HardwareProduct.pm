package Conch::Route::HardwareProduct;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::HardwareProduct

=head1 METHODS

=head2 routes

Sets up the routes for /hardware_product:

    GET     /hardware_product
    POST    /hardware_product

    GET     /hardware_product/:hardware_product_id
    POST    /hardware_product/:hardware_product_id
    DELETE  /hardware_product/:hardware_product_id

=cut

sub routes {
    my $class = shift;
    my $hardware_product = shift; # secured, under /hardware_product

    $hardware_product->to({ controller => 'hardware_product' });

    # GET /hardware_product
    $hardware_product->get('/')->to('#list');

    # POST /hardware_product
    $hardware_product->post('/')->to('#create');

    {
        my $with_hardware_product = $hardware_product->under('/:hardware_product_id')
            ->to('#find_hardware_product');

        # GET /hardware_product/:hardware_product_id
        $with_hardware_product->get('/')->to('#get');

        # POST /hardware_product/:hardware_product_id
        $with_hardware_product->post('/')->to('#update');

        # DELETE /hardware_product/:hardware_product_id
        $with_hardware_product->delete('/')->to('#delete');
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
# vim: set ts=4 sts=4 sw=4 et :
