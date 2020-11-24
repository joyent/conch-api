package Conch::Plugin::JSONValidator;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

use feature 'unicode_strings';
use JSON::Schema::Draft201909 '0.017';
use YAML::PP;
use Mojo::JSON 'to_json';
use Path::Tiny;

=pod

=head1 NAME

Conch::Plugin::JSONValidator

=head1 SYNOPSIS

    $app->plugin('Conch::Plugin::JSONValidator');

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

Because values are being parsed from the URI string, all values are strings even if they look like
numbers.

On success, returns the validated data; on failure, an HTTP 400 response is prepared, using the
F<response.yaml#/$defs/QueryParamsValidationError> json response schema.

Population of missing data from specified defaults is performed.

=cut

    $app->helper(validate_query_params => sub ($c, $schema_name, $data = $c->req->query_params->to_hash) {
        my $validator = $c->json_schema_validator;
        my $result = $validator->evaluate($data, 'query_params.yaml#/$defs/'.$schema_name);
        if (not $result) {
            my @errors = $c->normalize_evaluation_result($result);
            $c->log->warn("FAILED query_params validation for schema $schema_name: ".to_json(\@errors));
            return $c->status(400, {
                error => 'query parameters did not match required format',
                data => $data,
                details => \@errors,
                schema => $c->url_for('/json_schema/query_params/'.$schema_name)->to_abs,
            });
        }

        # now underlay data defaults
        foreach my $annotation (grep $_->keyword eq 'default', $result->annotations) {
            # query parameters are always just a flat hashref
            die 'annotation data_location is not "": ', to_json($annotation)
                if length($annotation->instance_location);
            $data->%* = ( $annotation->annotation->%*, $data->%* );
        }

        $c->log->debug("Passed data validation for query_params schema $schema_name");
        return $data;
    });

=head2 validate_request

Given the name of a json schema in the request namespace, validate the provided payload against
it (defaulting to the request's json payload).

On success, returns the validated payload data; on failure, an HTTP 400 response is prepared,
using the F<response.yaml#/$defs/RequestValidationError> json response schema.

=cut

    $app->helper(validate_request => sub ($c, $schema_name, $data = $c->req->json) {
        my $validator = $c->json_schema_validator;
        my $result = $validator->evaluate($data, 'request.yaml#/$defs/'.$schema_name);
        if (not $result) {
            my @errors = $c->normalize_evaluation_result($result);
            $c->log->warn("FAILED request payload validation for schema $schema_name: ".to_json(\@errors));
            return $c->status(400, {
                error => 'request did not match required format',
                details => \@errors,
                schema => $c->url_for('/json_schema/request/'.$schema_name)->to_abs,
                # data is not included here because it could be large, and it is exactly what was sent.
            });
        }

        $c->log->debug("Passed data validation for request schema $schema_name");
        return $data;
    });

=head2 json_schema_validator

Returns a L<JSON::Schema::Draft201909> object with all JSON Schemas pre-loaded.

=cut

    my $_validator;
    $app->helper(json_schema_validator => sub ($c) {
        return $_validator if $_validator;
        $_validator = JSON::Schema::Draft201909->new(
            output_format => 'terse',
            validate_formats => 1,
            collect_annotations => 1,
        );
        # TODO: blocked on https://github.com/ingydotnet/yaml-libyaml-pm/issues/68
        # local $YAML::XS::Boolean = 'JSON::PP'; ... YAML::XS::LoadFile(...)
        my $yaml = YAML::PP->new(boolean => 'JSON::PP');
        $_validator->add_schema($_, $yaml->load_file('json-schema/'.$_))
            foreach map path($_)->basename, glob('json-schema/*.yaml');

        $_validator;
    });

=head2 normalize_evaluation_result

Rewrite a L<JSON::Schema::Draft201909::Result> to match the format used by
F<response.yaml#/$defs/JSONSchemaError>.

=cut

    $app->helper(normalize_evaluation_result => sub ($c, $result) {
        return if $result;
        return map +{
            data_location => $_->{instanceLocation},
            schema_location => $_->{keywordLocation},
            !exists $_->{absoluteKeywordLocation} ? ()
              : (absolute_schema_location => do {
                  my $uri = Mojo::URL->new($_->{absoluteKeywordLocation}
                      =~ s!(\w+)\.yaml#/\$defs/([^/]+)!/json_schema/$1/$2#!r);
                  $uri->fragment(undef) if not length $uri->fragment;
                  $uri->to_abs($c->req->url->base)->to_string;
                }),
            error => $_->{error},
        }, $result->TO_JSON->{errors}->@*;
    });
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
