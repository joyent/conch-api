# NAME

Conch::Controller::WorkspaceRelay

# METHODS

## list

List all relays located in the current workspace (as specified by :workspace\_id in the path)
or sub-workspaces beneath it.

Use `?active_minutes=X` to constrains results to those updated in the last X minutes.

Response uses the WorkspaceRelays json schema.

## get\_relay\_devices

Returns all the devices that have been reported by the provided relay that are located within
this workspace. (It doesn't matter if the relay itself was later moved to another workspace - we
just look at device locations.)

Response uses the Devices json schema.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
