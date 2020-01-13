package Conch::Route::HardwareProduct;

use Mojo::Base -strict;

=pod

=head1 NAME

Conch::Route::HardwareProduct

=head1 METHODS

=head2 routes

Sets up the routes for /hardware_product.

=cut

sub routes {
    my $class = shift;
    my $hardware_product = shift; # secured, under /hardware_product

    $hardware_product->to({ controller => 'hardware_product' });

    # GET /hardware_product
    $hardware_product->get('/')->to('#get_all');

    # POST /hardware_product
    $hardware_product->require_system_admin->post('/')->to('#create');

    {
        # /hardware_product/:hardware_product_id_or_other
        my $with_hardware_product_id_or_other = $hardware_product->under('/:hardware_product_id_or_other')
            ->to('#find_hardware_product');

        # GET /hardware_product/<:identifier>
        $with_hardware_product_id_or_other->get('/')->to('#get');

        # POST /hardware_product/<:identifier>
        $with_hardware_product_id_or_other->require_system_admin->post('/')->to('#update');

        # DELETE /hardware_product/<:identifier>
        $with_hardware_product_id_or_other->require_system_admin->delete('/')->to('#delete');
    }
}

1;
__END__

=pod

=head1 ROUTE ENDPOINTS

All routes require authentication.

=head2 C<GET /hardware_product>

=over 4

=item * Response: F<response.yaml#/definitions/HardwareProducts>

=back

=head2 C<POST /hardware_product>

=over 4

=item * Requires system admin authorization

=item * Request: F<request.yaml#/definitions/HardwareProductCreate>

=item * Response: Redirect to the created hardware product

=back

=head2 C<GET /hardware_product/:hardware_product_id_or_other>

Identifiers accepted: C<id>, C<sku>, C<name> and C<alias>.

=over 4

=item * Response: F<response.yaml#/definitions/HardwareProduct>

=back

=head2 C<POST /hardware_product/:hardware_product_id_or_other>

Identifiers accepted: C<id>, C<sku>, C<name> and C<alias>.

=over 4

=item * Requires system admin authorization

=item * Request: F<request.yaml#/definitions/HardwareProductUpdate>

=item * Response: Redirect to the updated hardware product

=back

=head2 C<DELETE /hardware_product/:hardware_product_id_or_other>

Identifiers accepted: C<id>, C<sku>, C<name> and C<alias>.

=over 4

=item * Requires system admin authorization

=item * Response: C<204 NO CONTENT>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
