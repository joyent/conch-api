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

            key is one of: name, alias, sku
    GET     /hardware_product/:hardware_product_id
    GET     /hardware_product/:hardware_product_key=value
    POST    /hardware_product/:hardware_product_id
    POST    /hardware_product/:hardware_product_key=value
    DELETE  /hardware_product/:hardware_product_id
    DELETE  /hardware_product/:hardware_product_key=value

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
        # /hardware_product/:hardware_product_id
        my $with_hardware_product_id = $hardware_product->under('/<hardware_product_id:uuid>')
            ->to('#find_hardware_product');

        # /hardware_product/<name=:hardware_product_name
        # /hardware_product/alias=:hardware_product_alias
        # /hardware_product/sku=:hardware_product_sku
        my $with_hardware_product_key_and_value =
            $hardware_product
                ->under('/<:hardware_product_key>=<:hardware_product_value>'
                    => [ hardware_product_key => [qw(name alias sku)] ])
                ->to('#find_hardware_product');

        foreach ($with_hardware_product_id, $with_hardware_product_key_and_value) {
            # GET /hardware_product/<:identifier>
            $_->get('/')->to('#get');

            # POST /hardware_product/<:identifier>
            $_->post('/')->to('#update');

            # DELETE /hardware_product/<:identifier>
            $_->delete('/')->to('#delete');
        }
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
