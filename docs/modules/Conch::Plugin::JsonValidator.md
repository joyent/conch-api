# Conch::Plugin::JsonValidator

## SYNOPSIS

```perl
$app->plugin('Conch::Plugin::JsonValidator');

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

Conch::Plugin::JsonValidator provides a mechanism to validate request and response payloads
from an API endpoint against a JSON Schema.

## HELPERS

These methods are made available on the `$c` object (the invocant of all controller methods,
and therefore other helpers).

### validate\_query\_params

Given the name of a json schema in the query\_params namespace, validate the provided data
against it (defaulting to the request's query parameters converted into a hashref: parameters
appearing once are scalars, parameters appearing more than once have their values in an
arrayref).

On success, returns the validated data; on failure, an HTTP 400 response is prepared, using the
QueryParamsValidationError json response schema.

### validate\_request

Given the name of a json schema in the request namespace, validate the provided payload against
it (defaulting to the request's json payload).

On success, returns the validated payload data; on failure, an HTTP 400 response is prepared,
using the RequestValidationError json response schema.

### get\_query\_params\_validator

Returns a [JSON::Validator](https://metacpan.org/pod/JSON%3A%3AValidator) object suitable for validating an endpoint's query parameters
(when transformed into a hashref: see ["validate\_query\_params"](#validate_query_params)).

Strings that look like numbers are converted into numbers, so strict 'integer' and 'number'
typing is possible. No default population is done yet though; see
[https://github.com/mojolicious/json-validator/issues/158](https://github.com/mojolicious/json-validator/issues/158).

### get\_request\_validator

Returns a [JSON::Validator](https://metacpan.org/pod/JSON%3A%3AValidator) object suitable for validating an endpoint's json request payload.

### get\_response\_validator

Returns a [JSON::Validator](https://metacpan.org/pod/JSON%3A%3AValidator) object suitable for validating an endpoint's json response payload.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
