# Conch::Controller::DeviceLocation

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/DeviceLocation.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/DeviceLocation.pm)

## METHODS

### get

Retrieves location data for the current device. **Note:** This information is not considered to
be canonical if the device is in the 'production' phase or later.

Response uses the DeviceLocation json schema.

### set

Sets the location for a device, given a valid rack id and rack unit. If there is an existing
occupant, it is removed; the new occupant's hardware\_product is updated to match the layout
(and its health is set to unknown if it changed).

### delete

Deletes the location data for a device, provided it has been assigned to a location

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
