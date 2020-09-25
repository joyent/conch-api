# Conch::Controller::Device

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/Device.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/Device.pm)

## METHODS

### find\_device

Chainable action that uses the `device_id`, `device_serial_number` or
`device_id_or_serial_number` provided in the stash (usually via the request URL) to look up a
device, and stashes the query to get to it in `device_rs`.

If `require_role` is provided in the stash, it is used as the minimum required role for the user to
continue; otherwise the user must be a registered relay user or a system admin.

If `phase_earlier_than` is provided in the stash, `409 Conflict` is returned if the device is in
the provided phase (or later).

### get

Retrieves details about a single device. Response uses the DetailedDevice json schema.

**Note:** The results of this endpoint can be cached, but since the checksum is based only on
the device's last updated time, and not on any other components associated with it (disks,
network interfaces, location etc) it is only suitable for using to determine if a subsequent
device report has been submitted for this device (or columns directly on the device have been
updated). Updates to the device through other means (such as changing its location) may not be
reflected in the checksum.

### lookup\_by\_other\_attribute

Looks up one or more devices by a single query parameter (because these options are intended to
match only one or a very few device(s)). Supports:

```
/device?hostname=$hostname
/device?mac=$macaddr
/device?ipaddr=$ipaddr
/device?link=$link
/device?$setting_key=$setting_value
```

Response uses the Devices json schema.

### get\_pxe

Gets PXE-specific information about a device.

Response uses the DevicePXE json schema.

### set\_asset\_tag

Sets the `asset_tag` field on a device

### set\_validated

Sets the `validated` field on a device unless that field has already been set

### get\_phase

Gets just the device's phase. Response uses the DevicePhase json schema.

### get\_sku

Gets just the device's hardware\_product\_id and sku. Response uses the DeviceSku json schema.

### set\_phase

### add\_links

Appends the provided link(s) to the device record.

### remove\_links

When a payload is specified, remove specified links from the device record;
with a null payload, removes all links.

### set\_build

Moves the device to a new build.

Also requires read/write access to the old and new builds.

### set\_hardware\_product

Changes the hardware product (sku) assigned to the device.

Requires admin access to the device.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
