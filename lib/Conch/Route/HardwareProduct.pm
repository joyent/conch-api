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
    my $app = shift;

    return if $app->feature('no_db'); # for testing only

    $hardware_product->to({ controller => 'hardware_product' });

    # GET /hardware_product
    $hardware_product->get('/')->to('#get_all', response_schema => 'HardwareProducts');

    # forces the JSON Schema evaluator to re-load its data if the specification schema has changed
    my $specification_schema_version = $app->db_json_schemas->active
      ->resource('hardware_product', 'specification', 'latest')->get_column('version')->single // 0;
    my $check_for_changed_specification_schema = sub ($c) {
      my $new_version = $c->db_json_schemas->active
        ->resource('hardware_product', 'specification', 'latest')->get_column('version')->single // 0;
      if ($specification_schema_version != $new_version) {
        $c->_refresh_json_schema_validator;
        $specification_schema_version = $new_version;
      }
      return 1;
    };

    # POST /hardware_product
    $hardware_product->require_system_admin
      ->under($check_for_changed_specification_schema)
      ->under('/')->to('#extract_from_device_report', request_schema => 'HardwareProductCreate')
      ->post('/')->to('#create');

    {
        $hardware_product->any('/<:hardware_product_key>=<:hardware_product_value>/*optional',
                [ hardware_product_key => [qw(name alias sku)] ],
                { optional => '', query_params_schema => 'Anything', request_schema => 'Anything' },
            sub ($c) {
                $c->req->url->query->pairs;  # force normalization
                $c->status(308, $c->req->url->path_query =~ s/(?:name|alias|sku)=//r)
            });

        my $with_hardware_product_id_or_other = $hardware_product->under('/:hardware_product_id_or_other')
            ->to('#find_hardware_product');

        # GET /hardware_product/:hardware_product_id_or_other
        $with_hardware_product_id_or_other
          ->under($check_for_changed_specification_schema)
          ->get('/')->to('#get', response_schema => 'HardwareProduct');

        my $hwp_with_admin = $with_hardware_product_id_or_other->require_system_admin;

        # POST /hardware_product/:hardware_product_id_or_other
        $hwp_with_admin
          ->under($check_for_changed_specification_schema)
          ->under('/')->to('#extract_from_device_report', request_schema => 'HardwareProductUpdate')
          ->post('/')->to('#update');

        # DELETE /hardware_product/:hardware_product_id_or_other
        $hwp_with_admin->delete('/')->to('#delete');

        # PUT /hardware_product/:hardware_product_id_or_other/specification?path=:json_pointer_to_data
        $hwp_with_admin
          ->under($check_for_changed_specification_schema)
          ->put('/specification')->to('#set_specification', query_params_schema => 'HardwareProductSpecification', request_schema => 'Anything');

        # DELETE /hardware_product/:hardware_product_id_or_other/specification?path=:json_pointer_to_data
        $hwp_with_admin
          ->under($check_for_changed_specification_schema)
          ->delete('/specification')->to('#delete_specification', query_params_schema => 'HardwareProductSpecification');


        my $hw_with_schema = $with_hardware_product_id_or_other->any('/json_schema');

        # GET /hardware/:hardware_product_id_or_other/json_schema
        $hw_with_schema->get('/')->to('hardware_product#get_json_schema_metadata', response_schema => 'HardwareJSONSchemaDescriptions');

        my $hw_with_schema_id = $hw_with_schema->require_system_admin
          ->under('/<json_schema_id:uuid>')->to('JSONSchema#find_json_schema');

        my $hw_with_schema_version_int = $hw_with_schema->require_system_admin
          ->under('/<json_schema_type:json_pointer_token>/<json_schema_name:json_pointer_token>/:json_schema_version', [ json_schema_version => qr/[0-9]+/ ])->to('JSONSchema#find_json_schema')
          ->under('/')->to('JSONSchema#assert_active');

        # POST /hardware/:hardware_product_id_or_other/json_schema/:json_schema_id
        # POST /hardware/:hardware_product_id_or_other/json_schema/:json_schema_type/:json_schema_name/:json_schema_version
        $_->post('/')->to('hardware_product#add_json_schema')
          foreach $hw_with_schema_id, $hw_with_schema_version_int;

        # DELETE /hardware/:hardware_product_id_or_other/json_schema/:json_schema_id
        # DELETE /hardware/:hardware_product_id_or_other/json_schema/:json_schema_type/:json_schema_name/:json_schema_version
        $_->delete('/')->to('hardware_product#remove_json_schema')
          foreach $hw_with_schema_id, $hw_with_schema_version_int;

        # DELETE /hardware/:hardware_product_id_or_other/json_schema
        $hw_with_schema->require_system_admin->delete('/')->to('hardware_product#remove_all_json_schemas');
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

=item * Response: C<201 Created>, plus Location header

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

=item * Response: C<204 No Content>, plus Location header

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
the schema available from C<GET /json_schema/hardware_product/specification/latest>.

=item * Response: C<204 No Content>

=back

=head2 C<DELETE /hardware_product/:hardware_product_id_or_other/specification?path=:path_to_data>

Deletes a specific part of the json blob data in the C<specification> field, treating the URI query
parameter C<path> as the JSON pointer to the data to be removed. All other properties in the json
blob are left untouched.

After the delete operation, the C<specification> property must validate against
the schema available from C<GET /json_schema/hardware_product/specification/latest>.

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::HardwareProduct/delete_specification>

=item * Response: C<204 No Content>

=back

=head2 C<GET /hardware/:hardware_product_id_or_other/json_schema>

Retrieves a summary of the JSON Schemas configured to be used as validations for the indicated
hardware. Note the timestamp and user information are for when the JSON Schema was added for
the hardware, not when the schema itself was created.

=over 4

=item * Controller/Action: L<Conch::Controller::HardwareProduct/get_json_schema_metadata>

=item * Response: F<response.yaml#/$defs/HardwareJSONSchemaDescriptions>

=back

=head2 C<POST /hardware/:hardware_product_id_or_other/json_schema/:json_schema_id>

=head2 C<POST /hardware/:hardware_product_id_or_other/json_schema/:json_schema_type/:json_schema_name/:json_schema_version>

Adds the indicated JSON Schema to the list of validations for the indicated hardware.

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::HardwareProduct/add_json_schema>

=item * Request: F<request.yaml#/$defs/Null>

=item * Response: C<201 Created>

=back

=head2 C<DELETE /hardware/:hardware_product_id_or_other/json_schema/:json_schema_id>

=head2 C<DELETE /hardware/:hardware_product_id_or_other/json_schema/:json_schema_type/:json_schema_name/:json_schema_version>

Removes the indicated JSON Schema from the list of validations for the indicated hardware.

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::HardwareProduct/remove_json_schema>

=item * Response: C<204 No Content>

=back

=head2 C<DELETE /hardware/:hardware_product_id_or_other/json_schema>

Removes B<all> the JSON Schemas from the list of validations for the indicated hardware.

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::HardwareProduct/remove_all_json_schemas>

=item * Response: C<204 No Content>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set sts=2 sw=2 et :
