# Conch::Controller::WorkspaceRelay

## METHODS

### get\_all

List all relays located in the indicated workspace and sub-workspaces beneath it.
Note that this information is only accurate if the device the relay(s) reported
have not since been moved to another location.

Use `?active_minutes=X` to constrain results to those updated in the last X minutes.

Response uses the WorkspaceRelays json schema.

### get\_relay\_devices

Returns all the devices that have been reported by the provided relay that are located within
this workspace. (It doesn't matter if the relay itself was later moved to another workspace - we
just look at device locations.)

Response uses the Devices json schema.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
