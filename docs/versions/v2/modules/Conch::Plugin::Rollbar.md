# NAME

Conch::Plugin::Rollbar

# DESCRIPTION

Mojo plugin to send exceptions to [Rollbar](https://rollbar.com)

# METHODS

## register

Adds \`send\_exception\_to\_rollbar\` to Mojolicious app

## send\_exception\_to\_rollbar

Asynchronously send exception details to Rollbar if 'rollbar\_access\_token' is
configured. Returns a unique uuid suitable for logging, to correlate with the
Rollbar entry thus created.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
