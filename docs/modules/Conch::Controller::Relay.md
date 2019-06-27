# NAME

Conch::Controller::Relay

# METHODS

## register

Registers a relay and connects it with the current user. The relay is created if the relay does
not already exist, or is updated with additional payload information otherwise.

## list

If the user is a system admin, retrieve a list of all active relays in the database.
Requires the user to be a system admin.

Response uses the Relays json schema.

## get

Get the details of a single relay.
Requires the user to be a system admin, or have previously registered the relay.

Response uses the Relay json schema.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
