# Conch::Controller::DeviceLocation

## METHODS

### get

Retrieves location data for the current device. **Note:** This information is not considered to
be canonical if the device is in the 'production' phase or later.

Response uses the DeviceLocation json schema.

### set

Sets the location for a device, given a valid rack id and rack unit. The existing occupant is
removed, if there is one. The device is created based on the hardware\_product specified for
the layout if it does not yet exist.

### delete

Deletes the location data for a device, provided it has been assigned to a location

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
