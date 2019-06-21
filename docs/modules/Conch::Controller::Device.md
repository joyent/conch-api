# NAME

Conch::Controller::Device

# METHODS

## find\_device

Chainable action that validates the 'device\_id' provided in the path.

## get

Retrieves details about a single (active) device. Response uses the DetailedDevice json schema.

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

## graduate

Marks the device as "graduated" (VLAN flipped)

## set\_triton\_reboot

Sets the `latest_triton_reboot` field on a device

## set\_triton\_uuid

Sets the `triton_uuid` field on a device, given a triton\_uuid field that is a
valid UUID

## set\_triton\_setup

If a device has been marked as rebooted into Triton and has a Triton UUID, sets
the `triton_setup` field. Fails if the device has already been marked as such.

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
