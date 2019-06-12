package Conch::Plugin::JsonValidator;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

use JSON::Validator;
use Mojo::Util 'decamelize';

=pod

=head1 NAME

Conch::Plugin::JsonValidator

=head1 SYNOPSIS

    app->plugin('Conch::Plugin::JsonValidator');

    [ ... in a controller ]

    sub endpoint ($c) {
        my $body = $c->validate_request('MyRequestDefinition');
        ...
    }

=head1 DESCRIPTION

Conch::Plugin::JsonValidator provides a mechanism to validate request and response payloads
from an API endpoint against a JSON Schema.

=head1 HELPERS

=cut

sub register ($self, $app, $config) {


=head2 validate_request

Given the name of a json schema in the request namespace, validate the provided payload against
it (defaulting to the request's json payload).

On success, returns the validated payload data; on failure, an HTTP 400 response is prepared,
using the RequestValidationError json response schema.

=cut

    $app->helper(validate_request => sub ($c, $schema_name, $data = $c->req->json) {
        my $validator = $c->get_request_validator;
        my $schema = $validator->get('/definitions/'.$schema_name);

        if (not $schema) {
            Mojo::Exception->throw("unable to locate schema $schema");
            return;
        }

        if (my @errors = $validator->validate($data, $schema)) {
            $c->log->error("FAILED data validation for schema $schema_name".join(' // ', @errors));
            return $c->status(400, {
                error => 'request did not match required format',
                details => \@errors,
                schema => $c->url_for('/schema/request/'.decamelize($schema_name)),
            });
        }

        $c->log->debug("Passed data validation for request schema $schema_name");
        return $data;
    });


=head2 get_request_validator

Returns a L<JSON::Validator> object suitable for validating an endpoint's request payload.

=cut

    my $_request_validator;
    $app->helper(get_request_validator => sub ($c) {
        return $_request_validator if $_request_validator;
        $_request_validator = JSON::Validator->new;
        # FIXME: JSON::Validator should be picking this up out of the schema on its own.
        $_request_validator->load_and_validate_schema(
            'json-schema/request.yaml',
            { schema => 'http://json-schema.org/draft-07/schema#' });
        return $_request_validator;
    });


=head2 get_response_validator

Returns a L<JSON::Validator> object suitable for validating an endpoint's json response payload.

=cut

    my $_response_validator;
    $app->helper(get_response_validator => sub ($c) {
        return $_response_validator if $_response_validator;
        my $_response_validator = JSON::Validator->new;
        # FIXME: JSON::Validator should be picking this up out of the schema on its own.
        $_response_validator->load_and_validate_schema(
            'json-schema/response.yaml',
            { schema => 'http://json-schema.org/draft-07/schema#' });
        return $_response_validator;
    });
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
