# NAME

Conch::Route::Build

# METHODS

## routes

Sets up the routes for /build.

Unless otherwise noted, all routes require authentication.

### `GET /build`

Takes one optional query parameter `device_health` (defaults to false) to include
correlated counts of devices having each health value.

- Response: response.yaml#/Builds

### `POST /build`

- Requires system admin authorization
- Request: request.yaml#/BuildCreate
- Response: Redirect to the build

### `GET /build/:build_id_or_name`

Takes one optional query parameter `device_health` (defaults to false) to include counts
of devices having each health value.

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
- Response: `204 NO CONTENT`

### `DELETE /build/:build_id_or_name/user/#target_user_id_or_email?send_mail=<1|0`>

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the user.

- Requires system admin authorization or the admin role on the build
- Response: `204 NO CONTENT`

### `GET /build/:build_id_or_name/organization`

- User requires the admin role
- Response: [response.json#/definitions/BuildOrganizations](../json-schema/response.json#/definitions/BuildOrganizations)

### `POST /build/:build_id_or_name/organization?send_mail=<1|0>`

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the organization members and build admins.

- User requires the admin role
- Request: [request.json#/definitions/BuildAddOrganization](../json-schema/request.json#/definitions/BuildAddOrganization)
- Response: `204 NO CONTENT`

### `DELETE /build/:build_id_or_name/organization/:organization_id_or_name?send_mail=<1|0>`

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the organization members and build admins.

- User requires the admin role
- Response: `204 NO CONTENT`

### `GET /build/:build_id_or_name/device`

- Requires system admin authorization or the read-only role on the build
- Response: response.yaml#/Devices

### `POST /build/:build_id_or_name/device`

- Requires system admin authorization, or the read/write role on the build and the
read-only role on the device.
- Request: [request.json#/definitions/BuildCreateDevice](../json-schema/request.json#/definitions/BuildCreateDevice)
- Response: `204 NO CONTENT`

### `POST /build/:build_id_or_name/device/:device_id_or_serial_number`

- Requires system admin authorization, or the read/write role on the build and the
read-only role on the device (via a workspace or a relay registration, see
["routes" in Conch::Route::Device](../modules/Conch::Route::Device#routes))
- Response: `204 NO CONTENT`

### `DELETE /build/:build_id_or_name/device/:device_id_or_serial_number`

- Requires system admin authorization, or the read/write role on the build
- Response: `204 NO CONTENT`

### `GET /build/:build_id_or_name/rack`

- Requires system admin authorization or the read-only role on the build
- Response: response.yaml#/Racks

### `POST /build/:build_id_or_name/rack/:rack_id`

- Requires system admin authorization, or the read/write role on the build and the
read-only role on a workspace that contains the rack
- Response: `204 NO CONTENT`

### `DELETE /build/:build_id_or_name/rack/:rack_id`

- Requires system admin authorization, or the read/write role on the build
- Response: `204 NO CONTENT`

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
