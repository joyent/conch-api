# Conch::Plugin::Rollbar

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Plugin/Rollbar.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Plugin/Rollbar.pm)

## DESCRIPTION

Mojo plugin to send messages and exceptions to [Rollbar](https://rollbar.com).

Also support sending various errors to Rollbar, depending on matching criteria.

## HOOKS

### before\_render

Sends exceptions to Rollbar.

## EVENTS

### dispatch\_message\_payload

Listens to the `dispatch_message_payload` event (which is sent by the dispatch logger in
[Conch::Plugin::Logging](../modules/Conch%3A%3APlugin%3A%3ALogging)). When an error response is generated (any 4xx response code other
than 401 or 404), and a request header matches a key in the `rollbar` config
`error_match_header`, and the header value matches the corresponding regular expression, a
message is sent to Rollbar.

## HELPERS

These methods are made available on the `$c` object (the invocant of all controller methods,
and therefore other helpers).

### send\_exception\_to\_rollbar

Asynchronously send exception details to Rollbar (if the `rollbar` `access_token` is
configured). Returns a unique uuid suitable for logging, to correlate with the Rollbar entry
thus created.

### send\_message\_to\_rollbar

Asynchronously send a message to Rollbar (if the `rollbar` `access_token` is configured).
Returns a unique uuid suitable for logging, to correlate with the Rollbar entry thus created.

Requires a message string.
A hashref of additional data is optional.
A string or data structure of fingerprint data for grouping occurrences is optional.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
