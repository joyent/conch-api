# NAME

Conch::Plugin::Rollbar

# DESCRIPTION

Mojo plugin to send messages and exceptions to [Rollbar](https://rollbar.com).

# HOOKS

## before\_render

Sends exceptions to Rollbar.

# HELPERS

## send\_exception\_to\_rollbar

Asynchronously send exception details to Rollbar (if `rollbar_access_token` is
configured). Returns a unique uuid suitable for logging, to correlate with the
Rollbar entry thus created.

## send\_message\_to\_rollbar

Asynchronously send a message to Rollbar (if `rollbar_access_token` is configured). Returns a
unique uuid suitable for logging, to correlate with the Rollbar entry thus created.

Requires a message string. A hashref of additional data is optional.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
