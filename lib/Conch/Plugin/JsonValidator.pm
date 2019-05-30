package Conch::Plugin::JsonValidator;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

use feature 'unicode_strings', 'fc';
use JSON::Validator;

=pod

=head1 NAME

Conch::Plugin::JsonValidator

=head1 SYNOPSIS

    $app->plugin('Conch::Plugin::JsonValidator');

    [ ... in a controller ]

    sub endpoint ($c) {
        my $query_params = $c->validate_query_params('MyQueryParamsDefinition');
        return if not $query_params;

        my $body = $c->validate_request('MyRequestDefinition');
        return if not $body;
        ...
    }

=head1 DESCRIPTION

Provides a mechanism to validate request and response payloads from an API endpoint against a
JSON Schema.

=head1 METHODS

=head2 register

Sets up the helpers.

=head1 HELPERS

These methods are made available on the C<$c> object (the invocant of all controller methods,
and therefore other helpers).

=cut

sub register ($self, $app, $config) {

=head2 validate_query_params

Given the name of a json schema in the query_params namespace, validate the provided data
against it (defaulting to the request's query parameters converted into a hashref: parameters
appearing once are scalars, parameters appearing more than once have their values in an
arrayref).

On success, returns the validated data; on failure, an HTTP 400 response is prepared, using the
F<response.yaml#/definitions/QueryParamsValidationError> json response schema.

=cut

    $app->helper(validate_query_params => sub ($c, $schema_name, $data = $c->req->query_params->to_hash) {
        my $validator = $c->get_query_params_validator;
        my $schema = $validator->get('/definitions/'.$schema_name);

        if (not $schema) {
            Mojo::Exception->throw("unable to locate query_params schema $schema_name");
            return;
        }

        if (my @errors = $validator->validate($data, $schema)) {
            $c->log->warn("FAILED query_params validation for schema $schema_name: ".join(' // ', @errors));
            return $c->status(400, {
                error => 'query parameters did not match required format',
                data => $data,
                details => \@errors,
                schema => $c->url_for('/schema/query_params/'.$schema_name),
            });
        }

        $c->log->debug("Passed data validation for query_params schema $schema_name");
        return $data;
    });

=head2 validate_request

Given the name of a json schema in the request namespace, validate the provided payload against
it (defaulting to the request's json payload).

On success, returns the validated payload data; on failure, an HTTP 400 response is prepared,
using the F<response.yaml#/definitions/RequestValidationError> json response schema.

=cut

    $app->helper(validate_request => sub ($c, $schema_name, $data = $c->req->json) {
        my $validator = $c->get_request_validator;
        my $schema = $validator->get('/definitions/'.$schema_name);

        if (not $schema) {
            Mojo::Exception->throw("unable to locate request schema $schema_name");
            return;
        }

        if (my @errors = $validator->validate($data, $schema)) {
            $c->log->warn("FAILED request payload validation for schema $schema_name: ".join(' // ', @errors));
            return $c->status(400, {
                error => 'request did not match required format',
                details => \@errors,
                schema => $c->url_for('/schema/request/'.$schema_name),
            });
        }

        $c->log->debug("Passed data validation for request schema $schema_name");
        return $data;
    });

=head2 get_query_params_validator

Returns a L<JSON::Validator> object suitable for validating an endpoint's query parameters
(when transformed into a hashref: see L</validate_query_params>).

Strings that look like numbers are converted into numbers, so strict 'integer' and 'number'
typing is possible. No default population is done yet though; see
L<https://github.com/mojolicious/json-validator/issues/158>.

=cut

    my $_query_params_validator;
    $app->helper(get_query_params_validator => sub ($c) {
        return $_query_params_validator if $_query_params_validator;
        # TODO: ->new(coerce => '...,defaults')
        $_query_params_validator = JSON::Validator->new(coerce => 'numbers');
        $_query_params_validator->formats->@{qw(json-pointer uri uri-reference)} =
            (\&_check_json_pointer, \&_check_uri, \&_check_uri_reference);
        # FIXME: JSON::Validator should be extracting $schema out of the document - see https://github.com/mojolicious/json-validator/pull/152
        $_query_params_validator->load_and_validate_schema(
            'json-schema/query_params.yaml',
            { schema => 'http://json-schema.org/draft-07/schema#' });
        return $_query_params_validator;
    });

=head2 get_request_validator

Returns a L<JSON::Validator> object suitable for validating an endpoint's json request payload.

=cut

    my $_request_validator;
    $app->helper(get_request_validator => sub ($c) {
        return $_request_validator if $_request_validator;
        $_request_validator = JSON::Validator->new;
        $_request_validator->formats->@{qw(json-pointer uri uri-reference)} =
            (\&_check_json_pointer, \&_check_uri, \&_check_uri_reference);
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
        $_response_validator->formats->@{qw(json-pointer uri uri-reference)} =
            (\&_check_json_pointer, \&_check_uri, \&_check_uri_reference);
        # FIXME: JSON::Validator should be picking this up out of the schema on its own.
        $_response_validator->load_and_validate_schema(
            'json-schema/response.yaml',
            { schema => 'http://json-schema.org/draft-07/schema#' });
        return $_response_validator;
    });
}

# from JSON::Schema::Draft201909
sub _check_json_pointer {
  (!length($_[0]) || $_[0] =~ m{^/}) && $_[0] !~ m{~(?![01])}
    ? undef : 'Does not match json-pointer format.';
}

sub _check_uri {
  my $uri = Mojo::URL->new($_[0]);
  fc($uri->to_unsafe_string) eq fc($_[0]) && $uri->is_abs && $_[0] !~ /[^[:ascii:]]/
    ? undef : 'Does not match uri format.';
}

sub _check_uri_reference {
  fc(Mojo::URL->new($_[0])->to_unsafe_string) eq fc($_[0]) && $_[0] !~ /[^[:ascii:]]/
    ? undef : 'Does not match uri-reference format.';
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
