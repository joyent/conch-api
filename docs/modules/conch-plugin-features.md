# NAME

Conch::Plugin::Features - Sets up a helper to access configured features

## DESCRIPTION

Provides the helper sub 'feature' to the app and controllers:

```
if ($c->feature('rollbar') { ... }
```

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
