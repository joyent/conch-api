# NAME

Conch::Controller::Device

# METHODS

## find\_device

Chainable action that uses the 'device\_id\_or\_serial\_number' provided in the path
to find the device and verify the user has permissions to operate on it.

## get

Retrieves details about a single device. Response uses the DetailedDevice json schema.

## lookup\_by\_other\_attribute

Looks up one or more devices by query parameter. Supports:

```
/device?hostname=$hostname
/device?mac=$macaddr
/device?ipaddr=$ipaddr
/device?$setting_key=$setting_value
```

Response uses the Devices json schema.

## get\_pxe

Gets PXE-specific information about a device.

Response uses the DevicePXE json schema.

## set\_asset\_tag

Sets the `asset_tag` field on a device

## set\_validated

Sets the `validated` field on a device unless that field has already been set

## get\_phase

Gets just the device's phase. Response uses the DevicePhase json schema.

## set\_phase

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
