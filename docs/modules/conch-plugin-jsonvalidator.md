# NAME

Conch::Plugin::JsonValidator

# SYNOPSIS

```perl
app->plugin('Conch::Plugin::JsonValidator');

[ ... in a controller ]

sub endpoint ($c) {
    my $body = $c->validate_input('MyInputDefinition');

    [ ... ]

    $c->status_with_validation(200, MyOutputDefinition => $ret);
}
```

# DESCRIPTION

Conch::Plugin::JsonValidator provides an optional manner to validate input and
output from a Mojo controller against JSON Schema.

The `validate_input` helper uses the provided schema definition to validate
**JUST** the incoming JSON request. Headers and query parameters **ARE NOT**
validated. If the data fails validation, a 400 status is returned to user
with an error payload containing the validation errors.

The `status_with_validation` helper validates the outgoing data against the
provided schema definition. If the data validates, `status` is called, using
the provided status code and data. If the data validation fails, a
`Mojo::Exception` is thrown, returning a 500 to the user.

# SCHEMAS

`validate_input` validates data against the `json-schema/input.yaml` file.

# HELPERS

## validate\_input

Given a json schema name validate the provided input against it, and prepare a HTTP 400
response if validation failed; returns validated input on success.

## get\_input\_validator

Returns a [JSON::Validator](https://metacpan.org/pod/JSON::Validator) object suitable for validating an endpoint input.

## get\_response\_validator

Returns a [JSON::Validator](https://metacpan.org/pod/JSON::Validator) object suitable for validating an endpoint response.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
