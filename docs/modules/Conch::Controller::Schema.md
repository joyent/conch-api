# NAME

Conch::Controller::Schema

# METHODS

## get

Get the json-schema in JSON format.

## \_extract\_schema\_definition

Given a [JSON::Validator](https://metacpan.org/pod/JSON%3A%3AValidator) object containing a schema definition, extract the requested portion
out of the "definitions" section, including any named references, and add some standard
headers.

TODO: this (plus addition of the header fields) could mostly be replaced with just:

```perl
my $new_defs = $jv->bundle({
    schema => $jv->get('/definitions/'.$title),
    ref_key => 'definitions',
});
```

..except circular refs are not handled there, and the definition renaming leaks local path info.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
