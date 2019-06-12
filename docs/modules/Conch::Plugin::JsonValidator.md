# NAME

Conch::Plugin::JsonValidator

# SYNOPSIS

```perl
app->plugin('Conch::Plugin::JsonValidator');

[ ... in a controller ]

sub endpoint ($c) {
    my $body = $c->validate_request('MyRequestDefinition');
    ...
}
```

# DESCRIPTION

Conch::Plugin::JsonValidator provides a mechanism to validate request and response payloads
from an API endpoint against a JSON Schema.

# HELPERS

## validate\_request

Given the name of a json schema in the request namespace, validate the provided payload against
it (defaulting to the request's json payload).

On success, returns the validated payload data; on failure, an HTTP 400 response is prepared,
using the RequestValidationError json response schema.

## get\_request\_validator

Returns a [JSON::Validator](https://metacpan.org/pod/JSON::Validator) object suitable for validating an endpoint's request payload.

## get\_response\_validator

Returns a [JSON::Validator](https://metacpan.org/pod/JSON::Validator) object suitable for validating an endpoint's json response payload.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
