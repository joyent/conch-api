# Conch::Controller::DeviceSettings

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/DeviceSettings.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/DeviceSettings.pm)

## METHODS

### set\_all

Overrides all settings for a device with the given payload.
Existing settings are deactivated even if they are not being replaced with new ones.

### set\_single

Sets a single setting on a device. If the setting already exists, it is
overwritten, unless the value is unchanged.

### get\_all

Get all settings for a device as a hash

Response uses the DeviceSettings json schema.

### get\_single

Get a single setting from a device

Response uses the DeviceSetting json schema.

### delete\_single

Delete a single setting from a device, provide that setting was previously set

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
