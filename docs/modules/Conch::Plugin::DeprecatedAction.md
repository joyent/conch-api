# NAME

Conch::Plugin::DeprecationAction

# DESCRIPTION

Mojo plugin to detect and report the usage of deprecated controller actions.

# HOOKS

## around\_action

Sets the `X-Deprecated` header in the response.

Also sends a message to rollbar when a deprecated action is invoked, if the
`report_deprecated_actions` feature is enabled.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
