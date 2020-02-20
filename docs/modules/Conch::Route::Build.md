# Conch::Route::Build

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Route/Build.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Route/Build.pm)

## METHODS

### routes

Sets up the routes for /build.

## ROUTE ENDPOINTS

All routes require authentication.

### `GET /build`

Supports the following optional query parameters:

- `with_device_health` - includes correlated counts of devices having each health value
- `with_device_phases` - includes correlated counts of devices having each phase value
- `with_rack_phases` - includes correlated counts of racks having each phase value

- Response: response.yaml#/Builds

### `POST /build`

- Requires system admin authorization
- Request: request.yaml#/BuildCreate
- Response: Redirect to the build

### `GET /build/:build_id_or_name`

Supports the following optional query parameters:

- `with_device_health` - includes correlated counts of devices having each health value
- `with_device_phases` - includes correlated counts of devices having each phase value
- `with_rack_phases` - includes correlated counts of racks having each phase value

- Requires system admin authorization or the read-only role on the build
- Response: response.yaml#/Build

### `POST /build/:build_id_or_name`

- Requires system admin authorization or the admin role on the build
- Request: request.yaml#/BuildUpdate
- Response: Redirect to the build

### `GET /build/:build_id_or_name/user`

- Requires system admin authorization or the admin role on the build
- Response: response.yaml#/BuildUsers

### `POST /build/:build_id_or_name/user?send_mail=<1|0`>

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the user.

- Requires system admin authorization or the admin role on the build
- Request: request.yaml#/BuildAddUser
- Response: `204 No Content`

### `DELETE /build/:build_id_or_name/user/#target_user_id_or_email?send_mail=<1|0`>

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the user.

- Requires system admin authorization or the admin role on the build
- Response: `204 No Content`

### `GET /build/:build_id_or_name/organization`

- User requires the admin role
- Response: [response.json#/definitions/BuildOrganizations](../json-schema/response.json#/definitions/BuildOrganizations)

### `POST /build/:build_id_or_name/organization?send_mail=<1|0>`

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the organization members and build admins.

- User requires the admin role
- Request: [request.json#/definitions/BuildAddOrganization](../json-schema/request.json#/definitions/BuildAddOrganization)
- Response: `204 No Content`

### `DELETE /build/:build_id_or_name/organization/:organization_id_or_name?send_mail=<1|0>`

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the organization members and build admins.

- User requires the admin role
- Response: `204 No Content`

### `GET /build/:build_id_or_name/device`

Accepts the following optional query parameters:

- `health=:value` show only devices with the health matching the provided value
(can be used more than once)
- `active_minutes=:X` show only devices which have reported within the last X minutes
- `ids_only=1` only return device IDs, not full device details

- Requires system admin authorization or the read-only role on the build
- Response: [response.json#/definitions/Devices](../json-schema/response.json#/definitions/Devices), [response.json#/definitions/DeviceIds](../json-schema/response.json#/definitions/DeviceIds) or [response.json#/definitions/DeviceSerials](../json-schema/response.json#/definitions/DeviceSerials)

### `GET /build/:build_id_or_name/device/pxe`

- Requires system admin authorization or the read-only role on the build
- Response: [response.json#/definitions/DevicePXEs](../json-schema/response.json#/definitions/DevicePXEs)

### `POST /build/:build_id_or_name/device`

- Requires system admin authorization, or the read/write role on the build and the
read-write role on existing device(s) (via a workspace or build; see
["routes" in Conch::Route::Device](../modules/Conch%3A%3ARoute%3A%3ADevice#routes))
- Request: [request.json#/definitions/BuildCreateDevices](../json-schema/request.json#/definitions/BuildCreateDevices)
- Response: `204 No Content`

### `POST /build/:build_id_or_name/device/:device_id_or_serial_number`

- Requires system admin authorization, or the read/write role on the build and the
read-write role on the device (via a workspace or build; see ["routes" in Conch::Route::Device](../modules/Conch%3A%3ARoute%3A%3ADevice#routes))
- Response: `204 No Content`

### `DELETE /build/:build_id_or_name/device/:device_id_or_serial_number`

- Requires system admin authorization, or the read/write role on the build
- Response: `204 No Content`

### `GET /build/:build_id_or_name/rack`

- Requires system admin authorization or the read-only role on the build
- Response: response.yaml#/Racks

### `POST /build/:build_id_or_name/rack/:rack_id_or_name`

- Requires system admin authorization, or the read/write role on the build and the
read-write role on a workspace or build that contains the rack
- Response: `204 No Content`

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
