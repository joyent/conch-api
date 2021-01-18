package Conch::Plugin::JSONValidator;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

use JSON::Schema::Draft201909 '0.020';
use YAML::PP;
use Mojo::JSON 'to_json';
use Path::Tiny;
use List::Util qw(any none first);
use Try::Tiny;
use Safe::Isa;

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

On failure, an HTTP 400 response is prepared, using the
F<response.yaml#/$defs/QueryParamsValidationError> json response schema.

Population of missing data from specified defaults is performed.
Returns a boolean.

=cut

    $app->helper(validate_query_params => sub ($c, $schema_name, $data = $c->req->query_params->to_hash) {
        my $validator = $c->json_schema_validator;
        my $result = $validator->evaluate($data, 'query_params.yaml#/$defs/'.$schema_name, { collect_annotations => 1 });
        if (not $result) {
            my @errors = $c->normalize_evaluation_result($result);
            $c->log->warn("FAILED query_params validation for schema $schema_name: ".to_json(\@errors));
            $c->stash('response_schema', 'QueryParamsValidationError');
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
        return 1;
    });

=head2 validate_request

Given the name of a json schema in the request namespace, validate the provided payload against
it (defaulting to the request's json payload).

On failure, an HTTP 400 response is prepared, using the
F<response.yaml#/$defs/RequestValidationError> json response schema.

Returns a boolean.

=cut

    $app->helper(validate_request => sub ($c, $schema_name, $data = $c->req->json) {
        my $validator = $c->json_schema_validator;
        my $result = $validator->evaluate($data, 'request.yaml#/$defs/'.$schema_name);
        if (not $result) {
            my @errors = $c->normalize_evaluation_result($result);
            $c->log->warn("FAILED request payload validation for schema $schema_name: ".to_json(\@errors));
            $c->stash('response_schema', 'RequestValidationError');
            return $c->status(400, {
                error => 'request did not match required format',
                details => \@errors,
                schema => $c->url_for('/json_schema/request/'.$schema_name)->to_abs,
                # data is not included here because it could be large, and it is exactly what was sent.
            });
        }

        $c->log->debug("Passed data validation for request schema $schema_name");
        return 1;
    });

=head2 json_schema_validator

Returns a L<JSON::Schema::Draft201909> object with all JSON Schemas pre-loaded.

=cut

    my $_validator;
    my $_has_db = !$app->feature('no_db');
    $app->helper(json_schema_validator => sub ($c) {
        return $_validator if $_validator;
        $_validator = JSON::Schema::Draft201909->new(output_format => 'terse');
        # TODO: blocked on https://github.com/ingydotnet/yaml-libyaml-pm/issues/68
        # local $YAML::XS::Boolean = 'JSON::PP'; ... YAML::XS::LoadFile(...)
        my $yaml = YAML::PP->new(boolean => 'JSON::PP');
        try {
          $_validator->add_schema($_, $yaml->load_file('json-schema/'.$_))
            foreach map path($_)->basename, glob('json-schema/*.yaml');

          # some schemas have "$ref": "/json_schema/hardware_product/specification/latest"
          if ($_has_db) {
            if (my $row = $c->db_json_schemas->active
                ->resource('hardware_product', 'specification', 'latest')->single) {
              my $id_generator = sub ($row) { $c->url_for($row->canonical_path)->to_abs->to_string };
              my $schema = $row->schema_document($id_generator);
              $_validator->add_schema($_, $schema)
                foreach
                  $schema->{'$id'}, # absolute uri with .../<version>
                  '/json_schema/hardware_product/specification/latest'; # the actual $ref value
            }
          }
        }
        catch {
          require Data::Dumper;
          die 'problems adding schema (YAML is not parseable?) - ',
            Data::Dumper->new([ $_->$_isa('JSON::Schema::Draft201909::Result') ? $_->TO_JSON : $_ ])
              ->Indent(0)->Terse(1)->Dump;
        };

        $_validator;
    });

    # for internal use only! create a new validator so as to re-load everything (e.g. if an
    # underlying database resource has changed)
    $app->helper(_refresh_json_schema_validator => sub ($c) { undef $_validator });


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

=head2 add_link_to_schema

Adds a response header of the form:

    Link: <http://example.com/my-schema>; rel="describedby"

...indicating the JSON Schema that describes the response.

=cut

    $app->helper(add_link_to_schema => sub ($c, $schema) {
        my $url = $schema =~ /^http/ ? $schema : $c->url_for('/json_schema/response/'.$schema);
        $c->res->headers->link('<'.$url.'>; rel="describedby"');
    });


=head1 HOOKS

=head2 around_action

Before a controller action is executed, validate the incoming query parameters and request body
payloads against the schemas in the stash variables C<query_params_schema> and
C<request_schema>, respectively.

Performs more checks when this L<Conch::Plugin::Features/feature> is enabled:

=over 4

=item * C<validate_all_requests>

Assumes the query parameters schema is F<query_params.yaml#/$defs/Null> when not provided;
assumes the request body schema is F<request.yaml#/$defs/Null> when not provided (for
C<POST>, C<PUT>, C<DELETE> requests)

=back

=cut

    $app->hook(around_action => sub ($next, $c, $action, $last) {
        $c->stash('validated', { map +($_.'_schema' => []), qw(query_params request) })
            if not $c->stash('validated');

        my $query_params_schema = $c->stash('query_params_schema');
        $query_params_schema = 'Null'
            if not $query_params_schema and $last and not $c->stash('query_params')
                and $c->feature('validate_all_requests');

        if ($query_params_schema
                and none { $_ eq $query_params_schema } $c->stash('validated')->{query_params_schema}->@*) {
            my $query_params = $c->req->query_params->to_hash;
            return if not $c->validate_query_params($query_params_schema, $query_params);
            $c->stash('query_params', $query_params);

            # remember that we already ran this validation, so we don't do it again in a
            # subsequent route in the chain
            push $c->stash('validated')->{query_params_schema}->@*, $query_params_schema;
        }

        # TODO: also validate the schema(s) specified as the parameter when Content-Type
        # is application/schema+json or application/schema-instance+json

        my $request_schema = $c->stash('request_schema');
        my $method = $c->req->method;
        $request_schema = 'Null'
            if not $request_schema and $last and not $c->stash('request_data')
                and $c->feature('validate_all_requests');

        if ($request_schema
                and any { $method eq $_ } qw(POST PUT DELETE)
                and none { $_ eq $request_schema } $c->stash('validated')->{request_schema}->@*) {
            my $request_data = ($c->req->headers->content_type // '') =~ m{application/(?:[a-z-]+\+)?json}i ? $c->req->json : undef;
            return if not $c->validate_request($request_schema, $request_data);
            $c->stash('request_data', $request_data);

            # remember that we already ran this validation, so we don't do it again in a
            # subsequent route in the chain
            push $c->stash('validated')->{request_schema}->@*, $request_schema;
        }

        return $next->();
    });

=head2 after_dispatch

Runs after dispatching is complete.

Performs more checks when this L<Conch::Plugin::Features/feature> is enabled:

=over 4

=item * C<validate_all_responses>

When not provided, assumes the response body schema is F<response.yaml#/$defs/Null>
(for all 2xx responses), or F<response.yaml#/$defs/Error> (for 4xx responses).

=back

=cut

    $app->hook(after_dispatch => sub ($c) {
        return if ($c->res->headers->content_type // '')
            !~ m{application/(?:schema(?:-instance)?\+)?json}i;

        my $res_code = $c->res->code;
        return if not ($res_code >= 200 and $res_code < 300)
            and not ($res_code >= 400 and $res_code < 500);

        my $response_schema = $c->stash('response_schema');
        $response_schema = 'Error'
            if (not defined $response_schema or $response_schema !~ /Error$/)
                and $res_code >= 400 and $res_code < 500 and $c->res->json;
        $response_schema //= 'Null';
        $c->log->fatal('failed to specify exact response_schema used') if ref $response_schema;

        $c->add_link_to_schema($response_schema)
            if not ref $response_schema and $response_schema ne 'Null'
                and not $c->res->headers->link;

        return if not $c->feature('validate_all_responses');

        my $validator = $c->json_schema_validator;
        my $schema = !ref($response_schema)
            ? ($response_schema =~ /^http/ ? $response_schema
                : 'response.yaml#/$defs/'.$response_schema)
            : ref($response_schema) ne 'ARRAY' ? $response_schema
            : { anyOf => [ map +{ '$ref' => 'response.yaml#/$defs/'.$_ }, $response_schema->@* ] };

        # we don't track successes or failures when multiple schemas are provided, because we
        # don't know which schema is intended to match

        my @errors;
        $c->stash('response_validation_errors', { $response_schema => \@errors })
            if not ref $response_schema;
        my $schema_description = ref($response_schema) eq 'ARRAY'
            ? 'anyOf: ['.join(',',$response_schema->@*).']'
            : $response_schema;

        if (not (my $result = $validator->evaluate($c->res->json, $schema))) {
            @errors = $c->normalize_evaluation_result($result);

            if (my $notfound = first { $_->{error} =~ /EXCEPTION: unable to find resource / } @errors) {
                $c->log->fatal($notfound->{error} =~ s/^EXCEPTION: //r);
                return;
            }

            my $level = $INC{'Test/Conch.pm'} ? 'fatal' : 'warn';
            $c->log->$level('FAILED response payload validation for schema '.$schema_description.': '
                .to_json(\@errors));

            if ($c->feature('rollbar')) {
                my $endpoint = join '#', map $_//'', ($c->match->stack->[-1]//{})->@{qw(controller action)};
                $c->send_message_to_rollbar(
                    'error',
                    'failed response payload validation for schema '.$schema_description,
                    { endpoint => $endpoint, url => $c->req->url, errors => \@errors },
                    [ 'response schema validation failed', $endpoint ],
                );
            }
            return;
        }

        $c->log->debug('Passed data validation for response schema '.$schema_description);
        return;
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
# vim: set sts=2 sw=2 et :
