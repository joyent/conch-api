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

    $js->get('/common/HardwareProductSpecification',
       sub ($c) { $c->status(308, '/hardware_product/specification/latest') });

    # GET /json_schema/query_params/:json_schema_name
    # GET /json_schema/request/:json_schema_name
    # GET /json_schema/response/:json_schema_name
    # GET /json_schema/common/:json_schema_name
    # GET /json_schema/device_report/:json_schema_name
    $js->get('/:json_schema_type/<json_schema_name:json_pointer_token>',
            [ json_schema_type => [qw(query_params request response common device_report)] ])
        ->to('#get_from_disk', response_schema => 'JSONSchemaOnDisk');
}

=head2 secured_routes

Sets up the routes for /json_schema that require authentication.

=cut

sub secured_routes ($class, $schema) {
  $schema->to({ controller => 'JSONSchema' });

  # POST /json_schema/:json_schema_type/:json_schema_name
  $schema->post('/<json_schema_type:json_pointer_token>/<json_schema_name:json_pointer_token>')
    ->to('#create', request_schema => 'JSONSchema');

  my $with_schema_id = $schema->under('/<json_schema_id:uuid>')->to('#find_json_schema');

  my $with_schema_type = $schema->any('/<json_schema_type:json_pointer_token>');
  my $with_schema_type_name = $with_schema_type->any('/<json_schema_name:json_pointer_token>');

  my $with_schema_version_int = $with_schema_type_name
    ->under('/:json_schema_version', [ json_schema_version => qr/[0-9]+/ ])->to('#find_json_schema');
  my $with_schema_version_latest = $with_schema_type_name
    ->under('/latest', { json_schema_version => 'latest' })->to('#find_json_schema');

  # GET /json_schema/:json_schema_id
  # GET /json_schema/:json_schema_type/:json_schema_name/:json_schema_version
  # GET /json_schema/:json_schema_type/:json_schema_name/latest
  $_->get('/')->to('#get_single', response_schema => 'JSONSchema')
    foreach $with_schema_id, $with_schema_version_int, $with_schema_version_latest;

  # DELETE /json_schema/:json_schema_id
  # DELETE /json_schema/:json_schema_type/:json_schema_name/:json_schema_version
  $_->under('/')->to('#assert_active')->delete('/')->to('#delete')
    foreach $with_schema_id, $with_schema_version_int;

  # GET /json_schema/:json_schema_type
  $with_schema_type->get('/')
    ->to('#get_metadata', query_params_schema => 'JSONSchemaDescriptions', response_schema => 'JSONSchemaDescriptions');

  # GET /json_schema/:json_schema_type/:json_schema_name
  $with_schema_type_name->get('/')
    ->to('#get_metadata', query_params_schema => 'JSONSchemaDescriptions', response_schema => 'JSONSchemaDescriptions');
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

=item * Controller/Action: L<Conch::Controller::JSONSchema/get_from_disk>

=item * Response: a JSON Schema (F<response.yaml#/$defs/JSONSchemaOnDisk>) (Content-Type is
C<application/schema+json>).

=back

=head2 C<POST /json_schema/:json_schema_type/:json_schema_name>

Stores a new JSON Schema in the database. Unresolvable C<$ref>s are not permitted.

=over 4

=item * Controller/Action: L<Conch::Controller::JSONSchema/create>

=item * Request: F<request.yaml#/$defs/JSONSchema> (Content-Type is expected to be
C<application/schema+json>).

=item * Response: C<201 Created>, plus Location header

=back

=head2 C<GET /json_schema/:json_schema_id>

=head2 C<GET /json_schema/:json_schema_type/:json_schema_name/:json_schema_version>

=head2 C<GET /json_schema/:json_schema_type/:json_schema_name/latest>

Fetches the referenced JSON Schema document.

=over 4

=item * Controller/Action: L<Conch::Controller::JSONSchema/get_single>

=item * Response: F<response.yaml#/$defs/JSONSchema> (Content-Type is C<application/schema+json>).

=back

=head2 C<DELETE /json_schema/:json_schema_id>

=head2 C<DELETE /json_schema/:json_schema_type/:json_schema_name/:json_schema_version>

Deactivates the database entry for a single JSON Schema, rendering it unusable.
This operation is not permitted until all references from other documents have been removed,
exception of references using C<.../latest> which will now resolve to a different document
(and internal references will be re-verified).

If this JSON Schema was the latest of its series (C</json_schema/foo/bar/latest>), then that
C<.../latest> link will now resolve to an earlier version in the series.

=over 4

=item * Requires system admin authorization, if not the user who uploaded the document

=item * Controller/Action: L<Conch::Controller::JSONSchema/delete>

=item * Response: C<204 No Content>

=back

=head2 C<GET /json_schema/:json_schema_type>

=head2 C<GET /json_schema/:json_schema_type/:json_schema_name>

Gets meta information about all JSON Schemas in a particular type series, or a type and name series.

Optionally accepts the following query parameter:

=over 4

=item * C<active_only> (default C<0>): set to C<1> to only query for JSON Schemas that have not been
deactivated.

=item * C<with_hardware_products> (default C<0>): set to C<1> to include a list of hardware products
that reference each JSON Schema

=back

=over 4

=item * Controller/Action: L<Conch::Controller::JSONSchema/get_metadata>

=item * Response: F<response.yaml#/$defs/JSONSchemaDescriptions>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set sts=2 sw=2 et :
