package Conch::Route::HardwareProduct;

use Mojo::Base -strict;
use experimental 'signatures';

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
        $hardware_product->any('/<:hardware_product_key>=<:hardware_product_value>/*optional',
                [ hardware_product_key => [qw(name alias sku)] ], { optional => '' },
            sub ($c) {
                $c->req->url->query->pairs;  # force normalization
                $c->status(308, $c->req->url->path_query =~ s/(?:name|alias|sku)=//r)
            });

        my $with_hardware_product_id_or_other = $hardware_product->under('/:hardware_product_id_or_other')
            ->to('#find_hardware_product');

        # GET /hardware_product/:hardware_product_id_or_other
        $with_hardware_product_id_or_other->get('/')->to('#get');

        my $hwp_with_admin = $with_hardware_product_id_or_other->require_system_admin;

        # POST /hardware_product/:hardware_product_id_or_other
        $hwp_with_admin->post('/')->to('#update');

        # DELETE /hardware_product/:hardware_product_id_or_other
        $hwp_with_admin->delete('/')->to('#delete');

        # PUT /hardware_product/:hardware_product_id_or_other/specification?path=:json_pointer_to_data
        $hwp_with_admin->put('/specification')->to('#set_specification');

        # DELETE /hardware_product/:hardware_product_id_or_other/specification?path=:json_pointer_to_data
        $hwp_with_admin->delete('/specification')->to('#delete_specification');
    }
}

1;
__END__

=pod

=head1 ROUTE ENDPOINTS

All routes require authentication.

=head2 C<GET /hardware_product>

=over 4

=item * Controller/Action: L<Conch::Controller::HardwareProduct/get_all>

=item * Response: F<response.yaml#/$defs/HardwareProducts>

=back

=head2 C<POST /hardware_product>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::HardwareProduct/create>

=item * Request: F<request.yaml#/$defs/HardwareProductCreate>

=item * Response: Redirect to the created hardware product

=back

=head2 C<GET /hardware_product/:hardware_product_id_or_other>

Identifiers accepted: C<id>, C<sku>, C<name> and C<alias>.

=over 4

=item * Controller/Action: L<Conch::Controller::HardwareProduct/get>

=item * Response: F<response.yaml#/$defs/HardwareProduct>

=back

=head2 C<POST /hardware_product/:hardware_product_id_or_other>

Updates the indicated hardware product.

Identifiers accepted: C<id>, C<sku>, C<name> and C<alias>.

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::HardwareProduct/update>

=item * Request: F<request.yaml#/$defs/HardwareProductUpdate>

=item * Response: Redirect to the updated hardware product

=back

=head2 C<DELETE /hardware_product/:hardware_product_id_or_other>

Deactivates the indicated hardware product, preventing it from being used. All devices using this
hardware must be switched to other hardware first.

Identifiers accepted: C<id>, C<sku>, C<name> and C<alias>.

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::HardwareProduct/delete>

=item * Response: C<204 No Content>

=back

=head2 C<PUT /hardware_product/:hardware_product_id_or_other/specification?path=:path_to_data>

Sets a specific part of the json blob data in the C<specification> field, treating the URI query
parameter C<path> as the JSON pointer to the data to be added or modified. Existing data at the path
is overwritten without regard to type, so long as the JSON Schema is respected. For example, this
existing C<specification> field and this request:

  {
    "foo": { "bar": 123 },
    "x": { "y": [ 1, 2, 3 ] }
  }

  PUT /hardware_product/:hardware_product_id_or_other/specification?path=/foo/bar/baz  { "hello":1 }

Results in this data in C<specification>, changing the data type at node C</foo/bar>:

  {
    "foo": { "bar": { "baz": { "hello": 1 } } },
    "x": { "y": [ 1, 2, 3 ] }
  }

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::HardwareProduct/set_specification>

=item * Request: after the update operation, the C<specification> property must validate against
F<common.yaml#/$defs/HardwareProductSpecification>.

=item * Response: C<204 No Content>

=back

=head2 C<DELETE /hardware_product/:hardware_product_id_or_other/specification?path=:path_to_data>

Deletes a specific part of the json blob data in the C<specification> field, treating the URI query
parameter C<path> as the JSON pointer to the data to be removed. All other properties in the json
blob are left untouched.

After the delete operation, the C<specification> property must validate against
F<common.yaml#/$defs/HardwareProductSpecification>.

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::HardwareProduct/delete_specification>

=item * Response: C<204 No Content>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
