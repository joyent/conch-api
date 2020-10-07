# Conch::Plugin::Features - Sets up a helper to access configured features

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Plugin/Features.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Plugin/Features.pm)

## METHODS

### register

Sets up the helpers.

## HELPERS

These methods are made available on the `$c` object (the invocant of all controller methods,
and therefore other helpers).

### feature

Checks if a given feature name is enabled.

```
if ($c->feature('rollbar') { ... }
```

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
