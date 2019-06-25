# NAME

Conch::Route::Device

# METHODS

## routes

Sets up the routes for /device:

Unless otherwise noted, all routes require authentication.

The user's role (required for most endpoints) is determined by the rack location of the device,
and the workspace(s) the rack is contained in (where users are assigned a
[role](../modules/Conch::DB::Result::UserWorkspaceRole#role) in that workspace).

Full (admin-level) access is also granted to a device if a report was sent for that device
using a relay that registered with that user's credentials.

### `POST /device/:device_serial_number`

- Request: device\_report.yaml#/DeviceReport\_v3.0.0
- Response: response.yaml#/ValidationStateWithResults

### `GET /device?:key=:value`

Supports the following query parameters:

- `/device?hostname=:hostname`
- `/device?mac=:macaddr`
- `/device?ipaddr=:ipaddr`
- `/device?:setting_key=:setting_value`

The value of `:setting_key` and `:setting_value` are a device setting key and
value. For information on how to create a setting key or set its value see
below.

- Response: response.yaml#/Devices

### `GET /device/:device_id_or_serial_number`

- User requires the read-only role
- Response: response.yaml#/DetailedDevice

### `GET /device/:device_id_or_serial_number/pxe`

- User requires the read-only role
- Response: response.yaml#/DevicePXE

### `GET /device/:device_id_or_serial_number/phase`

- User requires the read-only role
- Response: response.yaml#/DevicePhase

### `POST /device/:device_id_or_serial_number/asset_tag`

- User requires the read/write role
- Request: request.yaml#/DeviceAssetTag
- Response: Redirect to the updated device

### `POST /device/:device_id_or_serial_number/validated`

- User requires the read/write role
- Request: request.yaml#/Null
- Response: Redirect to the updated device

### `POST /device/:device_id_or_serial_number/phase`

- User requires the read/write role
- Request: request.yaml#/DevicePhase
- Response: Redirect to the updated device

### `POST /device/:device_id_or_serial_number/links`

- User requires the read/write role
- Request: request.yaml#/DeviceLinks
- Response: Redirect to the updated device

### `DELETE /device/:device_id_or_serial_number/links`

- User requires the read/write role
- Response: 204 NO CONTENT

### `GET /device/:device_id_or_serial_number/location`

- User requires the read-only role
- Response: response.yaml#/DeviceLocation

### `POST /device/:device_id_or_serial_number/location`

- User requires the read/write role
- Request: request.yaml#/DeviceLocationUpdate
- Response: Redirect to the updated device

### `DELETE /device/:device_id_or_serial_number/location`

- User requires the read/write role
- Response: `204 NO CONTENT`

### `GET /device/:device_id_or_serial_number/settings`

- User requires the read-only role
- Response: response.yaml#/DeviceSettings

### `POST /device/:device_id_or_serial_number/settings`

- User requires the read/write role, or admin when overwriting existing
settings that do not start with `tag.`.
- Request: request.yaml#/DeviceSettings
- Response: `204 NO CONTENT`

### `GET /device/:device_id_or_serial_number/settings/:key`

- User requires the read-only role
- Response: response.yaml#/DeviceSetting

### `POST /device/:device_id_or_serial_number/settings/:key`

- User requires the read/write role, or admin when overwriting existing
settings that do not start with `tag.`.
- Request: request.yaml#/DeviceSettings
- Response: `204 NO CONTENT`

### `DELETE /device/:device_id_or_serial_number/settings/:key`

- User requires the read/write role for settings that start with `tag.`, and admin
otherwise.
- Response: `204 NO CONTENT`

### `POST /device/:device_id_or_serial_number/validation/:validation_id`

Does not store validation results.

- User requires the read/write role
- Request: device\_report.yaml
- Response: response.yaml#/ValidationResults

### `POST /device/:device_id_or_serial_number/validation_plan/:validation_plan_id`

Does not store validation results.

- User requires the read/write role
- Request: device\_report.yaml
- Response: response.yaml#/ValidationResults

### `GET /device/:device_id_or_serial_number/validation_state?status=<pass|fail|error>&status=...`

Accepts the query parameter `status`, indicating the desired status(es)
to search for (one of `pass`, `fail`, `error`). Can be used more than once.

- User requires the read-only role
- Response: response.yaml#/ValidationStatesWithResults

### `GET /device/:device_id_or_serial_number/interface`

- User requires the read-only role
- Response: response.yaml#/DeviceNics

### `GET /device/:device_id_or_serial_number/interface/:interface_name`

- User requires the read-only role
- Response: response.yaml#/DeviceNic

### `GET /device/:device_id_or_serial_number/interface/:interface_name/:field`

- User requires the read-only role
- Response: response.yaml#/DeviceNicField

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
