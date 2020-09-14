# Conch::Controller::JSONSchema

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/JSONSchema.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/JSONSchema.pm)

## METHODS

### get

Get a query parameters, request, response, common or device\_report JSON Schema (from
[query_params.json](../json-schema/query_params.json), [request.json](../json-schema/request.json), [response.json](../json-schema/response.json), [common.json](../json-schema/common.json), or [device_report.json](../json-schema/device_report.json),
respectively). Bundles all the referenced definitions together in the returned body response.

### \_extract\_schema\_definition

Given a [JSON::Validator](https://metacpan.org/pod/JSON%3A%3AValidator) object containing a schema definition, extract the requested portion
out of the `$defs` section, including any named references, and add some standard
headers.

TODO: this (plus addition of the header fields) could mostly be replaced with just:

```perl
my $new_defs = $jv->bundle({
    schema => $jv->get('/$defs/'.$name),
    ref_key => '$defs',
});
```

..except circular refs are not handled there, and the definition renaming leaks local path info.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
