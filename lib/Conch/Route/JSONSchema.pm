package Conch::Route::JSONSchema;

use Mojo::Base -strict, -signatures;
use Mojo::Util 'camelize';

=pod

=head1 NAME

Conch::Route::JSONSchema

=head1 METHODS

=head2 unsecured_routes

Sets up the routes for /json_schema that do not require authentication.

=cut

sub unsecured_routes ($class, $js) {
    # GET /schema/... now moved to /json_schema/...
    $js->root->get('/schema/:schema_type/:schema_name',
        [ schema_type => [qw(query_params request response)] ],
        { deprecated => 'v3.1' },
        sub ($c) {
            $c->status(308, $c->req->url->clone->path('/json_schema/'
                .$c->stash('schema_type').'/'.camelize($c->stash('schema_name'))));
        });

    $js->to({ controller => 'JSONSchema' });

    # GET /json_schema/query_params/:json_schema_name
    # GET /json_schema/request/:json_schema_name
    # GET /json_schema/response/:json_schema_name
    # GET /json_schema/common/:json_schema_name
    # GET /json_schema/device_report/:json_schema_name
    $js->get('/:json_schema_type/<json_schema_name:json_pointer_token>',
            [ json_schema_type => [qw(query_params request response common device_report)] ])
        ->to('#get', response_schema => 'JSONSchemaOnDisk');

    # TODO: this will become secured in v3.2, and handled directly by the main 'get' endpoint
    $js->get('/hardware_product/specification/:json_schema_version',
        { json_schema_version => qr/(?:1|latest)/ })
      ->to('#get', json_schema_type => 'common', json_schema_name => 'HardwareProductSpecification',
          response_schema => 'JSONSchemaOnDisk');
}

1;
__END__

=pod

=head1 ROUTE ENDPOINTS

=head2 C<GET /json_schema/query_params/:json_schema_name>

=head2 C<GET /json_schema/request/:json_schema_name>

=head2 C<GET /json_schema/response/:json_schema_name>

=head2 C<GET /json_schema/common/:json_schema_name>

=head2 C<GET /json_schema/device_report/:json_schema_name>

Returns the JSON Schema document specified by type and name, used for validating endpoint
requests and responses.

=over 4

=item * Does not require authentication.

=item * Controller/Action: L<Conch::Controller::JSONSchema/get>

=item * Response: a JSON Schema (F<response.yaml#/$defs/JSONSchemaOnDisk>) (Content-Type is
C<application/schema+json>).

=back

=head2 C<GET /json_schema/hardware_product/specification/latest>

Fetches the JSON Schema document used for describing the structure of the C<specification>
column of the C<hardware_product> database table.

Note: this is a special case of a generic endpoint to be added in Conch API version 3.2.
In the future, it will be modifiable; attempted modifications of this schema will be verified
against all existing C<hardware_product.specification> data, and any attempted modifications to
specification data will be verified against this schema.

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set sts=2 sw=2 et :
