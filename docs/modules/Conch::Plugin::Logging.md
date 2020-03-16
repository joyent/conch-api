# Conch::Plugin::Logging - Sets up logging for the application

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Plugin/Logging.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Plugin/Logging.pm)

## METHODS

### register

Initializes the logger object, and sets up hooks in various places to log request data and
process exceptions.

## HELPERS

These methods are made available on the `$c` object (the invocant of all controller methods,
and therefore other helpers).

### log

Returns the main [Conch::Log](../modules/Conch%3A%3ALog) object for the application, used for most logging.

### get\_logger

Returns a secondary [Conch::Log](../modules/Conch%3A%3ALog) object, to log specialized messages to a separate location.
Uses the provided `type` in the filename (e.g. `type => foo` will log to `foo.log`).

## HOOKS

### around\_dispatch

Makes the request's request id available to the logger object.

### before\_dispatch

Starts the `request_latency` timer.

### after\_dispatch

Logs the request and its response.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
