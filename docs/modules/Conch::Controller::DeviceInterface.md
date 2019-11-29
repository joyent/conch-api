# NAME

Conch::Controller::Device

# METHODS

## find\_device\_interface

Chainable action that uses the `interface_name` value provided in the stash (usually via the
request URL) to look up a device interface, and stashes the query to get to it in
`device_interface_rs`.

## get\_one\_field

Retrieves the value of the specified device\_nic field for the specified device interface.

Response uses the DeviceNicField json schema.

## get\_one

Retrieves all device\_nic fields for the specified device interface.

Response uses the DeviceNic json schema.

## get\_all

Retrieves all device\_nic records for the specified device.

Response uses the DeviceNics json schema.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
