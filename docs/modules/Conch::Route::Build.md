# Conch::Route::Build

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/Build.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/Build.pm)

## METHODS

### routes

Sets up the routes for /build.

## ROUTE ENDPOINTS

All routes require authentication.

### `GET /build`

Supports the following optional query parameters:

- `started=<0|1>` only return unstarted, or started, builds respectively
- `completed=<0|1>` only return incomplete, or complete, builds respectively

- Controller/Action: ["get\_all" in Conch::Controller::Build](../modules/Conch%3A%3AController%3A%3ABuild#get_all)
- Response: [response.json#/$defs/Builds](../json-schema/response.json#/$defs/Builds)

### `POST /build`

- Requires system admin authorization
- Controller/Action: ["create" in Conch::Controller::Build](../modules/Conch%3A%3AController%3A%3ABuild#create)
- Request: [request.json#/$defs/BuildCreate](../json-schema/request.json#/$defs/BuildCreate)
- Response: `201 Created`, plus Location header

### `GET /build/:build_id_or_name`

Supports the following optional query parameters:

- `with_device_health` - includes correlated counts of devices having each health value
- `with_device_phases` - includes correlated counts of devices having each phase value
- `with_rack_phases` - includes correlated counts of racks having each phase value

- Controller/Action: ["get" in Conch::Controller::Build](../modules/Conch%3A%3AController%3A%3ABuild#get)
- Requires system admin authorization or the read-only role on the build
- Response: [response.json#/$defs/Build](../json-schema/response.json#/$defs/Build)

### `POST /build/:build_id_or_name`

- Requires system admin authorization or the admin role on the build
- Controller/Action: ["update" in Conch::Controller::Build](../modules/Conch%3A%3AController%3A%3ABuild#update)
- Request: [request.json#/$defs/BuildUpdate](../json-schema/request.json#/$defs/BuildUpdate)
- Response: `204 No Content`, plus Location header

#### `POST /build/:build_id_or_name/links`

- Requires system admin authorization or the admin role on the build
- Controller/Action: ["add\_links" in Conch::Controller::Build](../modules/Conch%3A%3AController%3A%3ABuild#add_links)
- Request: [request.json#/$defs/BuildLinks](../json-schema/request.json#/$defs/BuildLinks)
- Response: `204 No Content`, plus Location header

#### `DELETE /build/:build_id_or_name/links`

- Requires system admin authorization or the admin role on the build
- Request: [request.json#/$defs/BuildLinksOrNull](../json-schema/request.json#/$defs/BuildLinksOrNull)
- Response: 204 NO CONTENT

### `GET /build/:build_id_or_name/user`

- Requires system admin authorization or the admin role on the build
- Controller/Action: ["get\_users" in Conch::Controller::Build](../modules/Conch%3A%3AController%3A%3ABuild#get_users)
- Response: [response.json#/$defs/BuildUsers](../json-schema/response.json#/$defs/BuildUsers)

### `POST /build/:build_id_or_name/user?send_mail=<1|0`>

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the user.

- Requires system admin authorization or the admin role on the build
- Controller/Action: ["add\_user" in Conch::Controller::Build](../modules/Conch%3A%3AController%3A%3ABuild#add_user)
- Request: [request.json#/$defs/BuildAddUser](../json-schema/request.json#/$defs/BuildAddUser)
- Response: `204 No Content`

### `DELETE /build/:build_id_or_name/user/#target_user_id_or_email?send_mail=<1|0`>

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the user.

- Requires system admin authorization or the admin role on the build
- Controller/Action: ["remove\_user" in Conch::Controller::Build](../modules/Conch%3A%3AController%3A%3ABuild#remove_user)
- Response: `204 No Content`

### `GET /build/:build_id_or_name/organization`

- User requires the admin role
- Controller/Action: ["get\_organizations" in Conch::Controller::Build](../modules/Conch%3A%3AController%3A%3ABuild#get_organizations)
- Response: [response.json#/$defs/BuildOrganizations](../json-schema/response.json#/$defs/BuildOrganizations)

### `POST /build/:build_id_or_name/organization?send_mail=<1|0>`

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the organization members and build admins.

- User requires the admin role
- Controller/Action: ["add\_organization" in Conch::Controller::Build](../modules/Conch%3A%3AController%3A%3ABuild#add_organization)
- Request: [request.json#/$defs/BuildAddOrganization](../json-schema/request.json#/$defs/BuildAddOrganization)
- Response: `204 No Content`

### `DELETE /build/:build_id_or_name/organization/:organization_id_or_name?send_mail=<1|0>`

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the organization members and build admins.

- User requires the admin role
- Controller/Action: ["remove\_organization" in Conch::Controller::Build](../modules/Conch%3A%3AController%3A%3ABuild#remove_organization)
- Response: `204 No Content`

### `GET /build/:build_id_or_name/device`

Accepts the following optional query parameters:

- `health=:value` show only devices with the health matching the provided value
(can be used more than once)
- `phase=:value` show only devices with the phase matching the provided value
(can be used more than once)
- `active_minutes=:X` show only devices which have reported within the last X minutes
- `ids_only=1` only return device IDs, not full device details

- Requires system admin authorization or the read-only role on the build
- Controller/Action: ["get\_devices" in Conch::Controller::Build](../modules/Conch%3A%3AController%3A%3ABuild#get_devices)
- Response: one of [response.json#/$defs/Devices](../json-schema/response.json#/$defs/Devices), [response.json#/$defs/DeviceIds](../json-schema/response.json#/$defs/DeviceIds) or [response.json#/$defs/DeviceSerials](../json-schema/response.json#/$defs/DeviceSerials)

### `GET /build/:build_id_or_name/device/pxe`

- Requires system admin authorization or the read-only role on the build
- Controller/Action: ["get\_pxe\_devices" in Conch::Controller::Build](../modules/Conch%3A%3AController%3A%3ABuild#get_pxe_devices)
- Response: [response.json#/$defs/DevicePXEs](../json-schema/response.json#/$defs/DevicePXEs)

### `POST /build/:build_id_or_name/device`

- Requires system admin authorization, or the read/write role on the build and the
read-only role on the device (via a build or a relay registration, see
["routes" in Conch::Route::Device](../modules/Conch%3A%3ARoute%3A%3ADevice#routes))
- Controller/Action: ["create\_and\_add\_devices" in Conch::Controller::Build](../modules/Conch%3A%3AController%3A%3ABuild#create_and_add_devices)
- Request: [request.json#/$defs/BuildCreateDevices](../json-schema/request.json#/$defs/BuildCreateDevices)
- Response: `204 No Content`

### `POST /build/:build_id_or_name/device/:device_id_or_serial_number`

- Requires system admin authorization, or the read/write role on the build and the
read-write role on the device (via a build; see ["routes" in Conch::Route::Device](../modules/Conch%3A%3ARoute%3A%3ADevice#routes))
- Controller/Action: ["add\_device" in Conch::Controller::Build](../modules/Conch%3A%3AController%3A%3ABuild#add_device)
- Request: [request.json#/$defs/Null](../json-schema/request.json#/$defs/Null)
- Response: `204 No Content`

### `DELETE /build/:build_id_or_name/device/:device_id_or_serial_number`

- Requires system admin authorization, or the read/write role on the build
- Controller/Action: ["remove\_device" in Conch::Controller::Build](../modules/Conch%3A%3AController%3A%3ABuild#remove_device)
- Response: `204 No Content`

### `GET /build/:build_id_or_name/rack`

Accepts the following optional query parameters:

- `phase=:value` show only racks with the phase matching the provided value
(can be used more than once)
- `ids_only=1` only return rack IDs, not full rack details

- Requires system admin authorization, or the read/write role on the build and the
read-only role on a build that contains the rack
- Controller/Action: ["get\_racks" in Conch::Controller::Build](../modules/Conch%3A%3AController%3A%3ABuild#get_racks)
- Response: one of [response.json#/$defs/Racks](../json-schema/response.json#/$defs/Racks) or [response.json#/$defs/RackIds](../json-schema/response.json#/$defs/RackIds)

### `POST /build/:build_id_or_name/rack/:rack_id_or_name`

- Requires system admin authorization, or the read/write role on the build and the
read-write role on a build that contains the rack
- Controller/Action: ["add\_rack" in Conch::Controller::Build](../modules/Conch%3A%3AController%3A%3ABuild#add_rack)
- Request: [request.json#/$defs/Null](../json-schema/request.json#/$defs/Null)
- Response: `204 No Content`

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
