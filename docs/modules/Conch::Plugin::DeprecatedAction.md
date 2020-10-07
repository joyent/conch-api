# Conch::Plugin::DeprecationAction

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Plugin/DeprecatedAction.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Plugin/DeprecatedAction.pm)

## DESCRIPTION

Mojo plugin to detect and report the usage of deprecated controller actions.

## METHODS

### register

Sets up the hooks.

## HOOKS

### after\_dispatch

Sets the `X-Deprecated` header in the response.

Also sends a message to Rollbar when a deprecated action is invoked, if the
`report_deprecated_actions` feature is enabled.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
