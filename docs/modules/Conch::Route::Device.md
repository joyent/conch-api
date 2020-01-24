# Conch::Route::Device

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Route/Device.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Route/Device.pm)

## METHODS

### routes

Sets up the routes for /device.

## ROUTE ENDPOINTS

All routes require authentication.

The user's role (required for most endpoints) is determined by the build the device is
contained in (where users are assigned a [role](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AUserBuildRole#role) in that
build), and the rack location of the device and the workspace(s) or build the rack is contained
in (where users are assigned a [role](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AUserBuildRole#role) in that build and
a [role](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AUserWorkspaceRole#role) in that workspace).

Full (admin-level) access is also granted to a device if a report was sent for that device
using a relay that registered with that user's credentials.

### `POST /device/:device_serial_number`

- Request: [device_report.json#/definitions/DeviceReport](../json-schema/device_report.json#/definitions/DeviceReport)
- Response: [response.json#/definitions/ValidationStateWithResults](../json-schema/response.json#/definitions/ValidationStateWithResults)

### `GET /device?:key=:value`

Supports the following query parameters:

- `hostname=:hostname`
- `mac=:macaddr`
- `ipaddr=:ipaddr`
- `:setting_key=:setting_value`

The value of `:setting_key` and `:setting_value` are a device setting key and
value. For information on how to create a setting key or set its value see
below.

- Response: [response.json#/definitions/Devices](../json-schema/response.json#/definitions/Devices)

### `GET /device/:device_id_or_serial_number`

- User requires the read-only role
- Response: [response.json#/definitions/DetailedDevice](../json-schema/response.json#/definitions/DetailedDevice)

### `GET /device/:device_id_or_serial_number/pxe`

- User requires the read-only role
- Response: [response.json#/definitions/DevicePXE](../json-schema/response.json#/definitions/DevicePXE)

### `GET /device/:device_id_or_serial_number/phase`

- User requires the read-only role
- Response: [response.json#/definitions/DevicePhase](../json-schema/response.json#/definitions/DevicePhase)

### `GET /device/:device_id_or_serial_number/sku`

- User requires the read-only role
- Response: [response.json#/definitions/DeviceSku](../json-schema/response.json#/definitions/DeviceSku)

### `POST /device/:device_id_or_serial_number/asset_tag`

- User requires the read/write role
- Request: [request.json#/definitions/DeviceAssetTag](../json-schema/request.json#/definitions/DeviceAssetTag)
- Response: Redirect to the updated device

### `POST /device/:device_id_or_serial_number/validated`

- User requires the read/write role
- Request: [request.json#/definitions/Null](../json-schema/request.json#/definitions/Null)
- Response: Redirect to the updated device

### `POST /device/:device_id_or_serial_number/phase`

- User requires the read/write role
- Request: [request.json#/definitions/DevicePhase](../json-schema/request.json#/definitions/DevicePhase)
- Response: Redirect to the updated device

### `POST /device/:device_id_or_serial_number/links`

- User requires the read/write role
- Request: [request.json#/definitions/DeviceLinks](../json-schema/request.json#/definitions/DeviceLinks)
- Response: Redirect to the updated device

### `DELETE /device/:device_id_or_serial_number/links`

- User requires the read/write role
- Response: 204 NO CONTENT

### `POST /device/:device_id_or_serial_number/build`

- User requires the read/write role for the device, as well as the old and new builds
- Request: [request.json#/definitions/DeviceBuild](../json-schema/request.json#/definitions/DeviceBuild)
- Response: Redirect to the updated device

### `GET /device/:device_id_or_serial_number/location`

- User requires the read-only role
- Response: [response.json#/definitions/DeviceLocation](../json-schema/response.json#/definitions/DeviceLocation)

### `POST /device/:device_id_or_serial_number/location`

- User requires the read/write role
- Request: [request.json#/definitions/DeviceLocationUpdate](../json-schema/request.json#/definitions/DeviceLocationUpdate)
- Response: Redirect to the updated device

### `DELETE /device/:device_id_or_serial_number/location`

- User requires the read/write role
- Response: `204 NO CONTENT`

### `GET /device/:device_id_or_serial_number/settings`

- User requires the read-only role
- Response: [response.json#/definitions/DeviceSettings](../json-schema/response.json#/definitions/DeviceSettings)

### `POST /device/:device_id_or_serial_number/settings`

- User requires the read/write role, or admin when overwriting existing
settings that do not start with `tag.`.
- Request: [request.json#/definitions/DeviceSettings](../json-schema/request.json#/definitions/DeviceSettings)
- Response: `204 NO CONTENT`

### `GET /device/:device_id_or_serial_number/settings/:key`

- User requires the read-only role
- Response: [response.json#/definitions/DeviceSetting](../json-schema/response.json#/definitions/DeviceSetting)

### `POST /device/:device_id_or_serial_number/settings/:key`

- User requires the read/write role, or admin when overwriting existing
settings that do not start with `tag.`.
- Request: [request.json#/definitions/DeviceSettings](../json-schema/request.json#/definitions/DeviceSettings)
- Response: `204 NO CONTENT`

### `DELETE /device/:device_id_or_serial_number/settings/:key`

- User requires the read/write role for settings that start with `tag.`, and admin
otherwise.
- Response: `204 NO CONTENT`

### `POST /device/:device_id_or_serial_number/validation/:validation_id`

Does not store validation results.

- User requires the read-only role
- Request: [device_report.json#/definitions/DeviceReport](../json-schema/device_report.json#/definitions/DeviceReport)
- Response: [response.json#/definitions/ValidationResults](../json-schema/response.json#/definitions/ValidationResults)

### `POST /device/:device_id_or_serial_number/validation_plan/:validation_plan_id`

Does not store validation results.

- User requires the read-only role
- Request: [device_report.json#/definitions/DeviceReport](../json-schema/device_report.json#/definitions/DeviceReport)
- Response: [response.json#/definitions/ValidationResults](../json-schema/response.json#/definitions/ValidationResults)

### `GET /device/:device_id_or_serial_number/validation_state?status=<pass|fail|error>&status=...`

Accepts the query parameter `status`, indicating the desired status(es)
to search for (one of `pass`, `fail`, `error`). Can be used more than once.

- User requires the read-only role
- Response: [response.json#/definitions/ValidationStatesWithResults](../json-schema/response.json#/definitions/ValidationStatesWithResults)

### `GET /device/:device_id_or_serial_number/interface`

- User requires the read-only role
- Response: [response.json#/definitions/DeviceNics](../json-schema/response.json#/definitions/DeviceNics)

### `GET /device/:device_id_or_serial_number/interface/:interface_name`

- User requires the read-only role
- Response: [response.json#/definitions/DeviceNic](../json-schema/response.json#/definitions/DeviceNic)

### `GET /device/:device_id_or_serial_number/interface/:interface_name/:field`

- User requires the read-only role
- Response: [response.json#/definitions/DeviceNicField](../json-schema/response.json#/definitions/DeviceNicField)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
