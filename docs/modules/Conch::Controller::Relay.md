# Conch::Controller::Relay

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Controller/Relay.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Controller/Relay.pm)

## METHODS

### register

Registers a relay and connects it with the current user. The relay is created if the relay does
not already exist, or is updated with additional payload information otherwise.

### get\_all

Retrieve a list of all active relays in the database.

Response uses the Relays json schema.

### find\_relay

Chainable action that uses the `relay_id_or_serial_number` provided in the stash (usually
via the request URL), and stashes the query to get to it in `relay_rs`.

The relay must have been registered by the user to continue; otherwise the user must be a
system admin.

### get

Get the details of a single relay.
Requires the user to be a system admin, or have previously registered the relay.

Response uses the Relay json schema.

### delete

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
