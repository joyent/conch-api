# NAME

Conch::Controller::Device

# METHODS

## find\_device

Chainable action that uses the `device_id_or_serial_number` provided in the path
to find the device and verify the user has the required role to operate on it.

If `require_role` is provided, it is used as the minimum required role for the user to
continue.

## get

Retrieves details about a single device. Response uses the DetailedDevice json schema.

**Note:** The results of this endpoint can be cached, but since the checksum is based only on
the device's last updated time, and not on any other components associated with it (disks,
network interfaces, location etc) it is only suitable for using to determine if a subsequent
device report has been submitted for this device. Updates to the device through other means may
not be reflected in the checksum.

## lookup\_by\_other\_attribute

Looks up one or more devices by query parameter. Supports:

```
/device?hostname=$hostname
/device?mac=$macaddr
/device?ipaddr=$ipaddr
/device?link=$link
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

## get\_sku

Gets just the device's hardware\_product\_id and sku. Response uses the DeviceSku json schema.

## set\_phase

## add\_links

Appends the provided link(s) to the device record.

## remove\_links

Removes all links from the device record.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
