# Conch::Plugin::JSONValidator

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Plugin/JSONValidator.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Plugin/JSONValidator.pm)

## SYNOPSIS

```perl
$app->plugin('Conch::Plugin::JSONValidator');

[ ... in a controller ]

sub endpoint ($c) {
    my $query_params = $c->validate_query_params('MyQueryParamsDefinition');
    return if not $query_params;

    my $body = $c->validate_request('MyRequestDefinition');
    return if not $body;
    ...
}
```

## DESCRIPTION

Provides a mechanism to validate request and response payloads from an API endpoint against a
JSON Schema.

## METHODS

### register

Sets up the helpers.

## HELPERS

These methods are made available on the `$c` object (the invocant of all controller methods,
and therefore other helpers).

### validate\_query\_params

Given the name of a json schema in the query\_params namespace, validate the provided data
against it (defaulting to the request's query parameters converted into a hashref: parameters
appearing once are scalars, parameters appearing more than once have their values in an
arrayref).

Because values are being parsed from the URI string, all values are strings even if they look like
numbers.

On failure, an HTTP 400 response is prepared, using the
[response.json#/$defs/QueryParamsValidationError](../json-schema/response.json#/$defs/QueryParamsValidationError) json response schema.

Population of missing data from specified defaults is performed.
Returns a boolean.

### validate\_request

Given the name of a json schema in the request namespace, validate the provided payload against
it (defaulting to the request's json payload).

On failure, an HTTP 400 response is prepared, using the
[response.json#/$defs/RequestValidationError](../json-schema/response.json#/$defs/RequestValidationError) json response schema.

Returns a boolean.

### json\_schema\_validator

Returns a [JSON::Schema::Draft201909](https://metacpan.org/pod/JSON%3A%3ASchema%3A%3ADraft201909) object with all JSON Schemas pre-loaded.

### normalize\_evaluation\_result

Rewrite a [JSON::Schema::Draft201909::Result](https://metacpan.org/pod/JSON%3A%3ASchema%3A%3ADraft201909%3A%3AResult) to match the format used by
[response.json#/$defs/JSONSchemaError](../json-schema/response.json#/$defs/JSONSchemaError).

## HOOKS

### around\_action

Before a controller action is executed, validate the incoming query parameters and request body
payloads against the schemas in the stash variables `query_params_schema` and
`request_schema`, respectively.

Performs more checks when this ["feature" in Conch::Plugin::Features](../modules/Conch%3A%3APlugin%3A%3AFeatures#feature) is enabled:

- `validate_all_requests`

    Assumes the query parameters schema is [query_params.json#/$defs/Null](../json-schema/query_params.json#/$defs/Null) when not provided;
    assumes the request body schema is [request.json#/$defs/Null](../json-schema/request.json#/$defs/Null) when not provided (for
    `POST`, `PUT`, `DELETE` requests)

### after\_dispatch

Runs after dispatching is complete.

Performs more checks when this ["feature" in Conch::Plugin::Features](../modules/Conch%3A%3APlugin%3A%3AFeatures#feature) is enabled:

- `validate_all_responses`

    When not provided, assumes the response body schema is [response.json#/$defs/Null](../json-schema/response.json#/$defs/Null)
    (for all 2xx responses), or [response.json#/$defs/Error](../json-schema/response.json#/$defs/Error) (for 4xx responses).

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
