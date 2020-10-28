# Conch::Route::Device

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/Device.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/Device.pm)

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

### `GET /device?:key=:value`

Supports the following query parameters:

- `hostname=:hostname`
- `mac=:macaddr`
- `ipaddr=:ipaddr`
- `:setting_key=:setting_value`

The value of `:setting_key` and `:setting_value` are a device setting key and
value. For information on how to create a setting key or set its value see
below.

- Controller/Action: ["lookup\_by\_other\_attribute" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#lookup_by_other_attribute)
- Response: [response.json#/definitions/Devices](../json-schema/response.json#/definitions/Devices)

### `GET /device/:device_id_or_serial_number`

- User requires the read-only role
- Controller/Action: ["get" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#get)
- Response: [response.json#/definitions/DetailedDevice](../json-schema/response.json#/definitions/DetailedDevice)

### `GET /device/:device_id_or_serial_number/pxe`

- User requires the read-only role
- Controller/Action: ["get\_pxe" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#get_pxe)
- Response: [response.json#/definitions/DevicePXE](../json-schema/response.json#/definitions/DevicePXE)

### `GET /device/:device_id_or_serial_number/phase`

- User requires the read-only role
- Controller/Action: ["get\_phase" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#get_phase)
- Response: [response.json#/definitions/DevicePhase](../json-schema/response.json#/definitions/DevicePhase)

### `GET /device/:device_id_or_serial_number/sku`

- User requires the read-only role
- Controller/Action: ["get\_sku" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#get_sku)
- Response: [response.json#/definitions/DeviceSku](../json-schema/response.json#/definitions/DeviceSku)

### `POST /device/:device_id_or_serial_number/asset_tag`

- User requires the read/write role
- Controller/Action: ["set\_asset\_tag" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#set_asset_tag)
- Request: [request.json#/definitions/DeviceAssetTag](../json-schema/request.json#/definitions/DeviceAssetTag)
- Response: Redirect to the updated device

### `POST /device/:device_id_or_serial_number/validated`

- User requires the read/write role
- Controller/Action: ["set\_validated" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#set_validated)
- Request: [request.json#/definitions/Null](../json-schema/request.json#/definitions/Null)
- Response: Redirect to the updated device

### `POST /device/:device_id_or_serial_number/phase`

- User requires the read/write role
- Controller/Action: ["set\_phase" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#set_phase)
- Request: [request.json#/definitions/DevicePhase](../json-schema/request.json#/definitions/DevicePhase)
- Response: Redirect to the updated device

### `POST /device/:device_id_or_serial_number/links`

- User requires the read/write role
- Controller/Action: ["add\_links" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#add_links)
- Request: [request.json#/definitions/DeviceLinks](../json-schema/request.json#/definitions/DeviceLinks)
- Response: Redirect to the updated device

### `DELETE /device/:device_id_or_serial_number/links`

- User requires the read/write role
- Controller/Action: ["remove\_links" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#remove_links)
- Request: [request.json#/definitions/DeviceLinksOrNull](../json-schema/request.json#/definitions/DeviceLinksOrNull)
- Response: 204 No Content

### `POST /device/:device_id_or_serial_number/build`

- User requires the read/write role for the device, as well as the old and new builds
- Controller/Action: ["set\_build" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#set_build)
- Request: [request.json#/definitions/DeviceBuild](../json-schema/request.json#/definitions/DeviceBuild)
- Response: Redirect to the updated device

### `POST /device/:device_id_or_serial_number/hardware_product`

### `POST /device/:device_id_or_serial_number/sku`

- User requires the admin role for the device
- Controller/Action: ["set\_hardware\_product" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#set_hardware_product)
- Request: [request.json#/definitions/DeviceHardware](../json-schema/request.json#/definitions/DeviceHardware)
- Response: Redirect to the updated device

### `GET /device/:device_id_or_serial_number/location`

- User requires the read-only role
- Controller/Action: ["get" in Conch::Controller::DeviceLocation](../modules/Conch%3A%3AController%3A%3ADeviceLocation#get)
- Response: [response.json#/definitions/DeviceLocation](../json-schema/response.json#/definitions/DeviceLocation)

### `POST /device/:device_id_or_serial_number/location`

- User requires the read/write role
- Controller/Action: ["set" in Conch::Controller::DeviceLocation](../modules/Conch%3A%3AController%3A%3ADeviceLocation#set)
- Request: [request.json#/definitions/DeviceLocationUpdate](../json-schema/request.json#/definitions/DeviceLocationUpdate)
- Response: Redirect to the updated device

### `DELETE /device/:device_id_or_serial_number/location`

- User requires the read/write role
- Controller/Action: ["delete" in Conch::Controller::DeviceLocation](../modules/Conch%3A%3AController%3A%3ADeviceLocation#delete)
- Response: `204 No Content`

### `GET /device/:device_id_or_serial_number/settings`

- User requires the read-only role
- Controller/Action: ["get\_all" in Conch::Controller::DeviceSettings](../modules/Conch%3A%3AController%3A%3ADeviceSettings#get_all)
- Response: [response.json#/definitions/DeviceSettings](../json-schema/response.json#/definitions/DeviceSettings)

### `POST /device/:device_id_or_serial_number/settings`

- User requires the read/write role, or admin when overwriting existing
settings that do not start with `tag.`.
- Controller/Action: ["set\_all" in Conch::Controller::DeviceSettings](../modules/Conch%3A%3AController%3A%3ADeviceSettings#set_all)
- Request: [request.json#/definitions/DeviceSettings](../json-schema/request.json#/definitions/DeviceSettings)
- Response: `204 No Content`

### `GET /device/:device_id_or_serial_number/settings/:key`

- User requires the read-only role
- Controller/Action: ["get\_single" in Conch::Controller::DeviceSettings](../modules/Conch%3A%3AController%3A%3ADeviceSettings#get_single)
- Response: [response.json#/definitions/DeviceSetting](../json-schema/response.json#/definitions/DeviceSetting)

### `POST /device/:device_id_or_serial_number/settings/:key`

- User requires the read/write role, or admin when overwriting existing
settings that do not start with `tag.`.
- Controller/Action: ["set\_single" in Conch::Controller::DeviceSettings](../modules/Conch%3A%3AController%3A%3ADeviceSettings#set_single)
- Request: [request.json#/definitions/DeviceSettings](../json-schema/request.json#/definitions/DeviceSettings)
- Response: `204 No Content`

### `DELETE /device/:device_id_or_serial_number/settings/:key`

- User requires the read/write role for settings that start with `tag.`, and admin
otherwise.
- Controller/Action: ["delete\_single" in Conch::Controller::DeviceSettings](../modules/Conch%3A%3AController%3A%3ADeviceSettings#delete_single)
- Response: `204 No Content`

### `POST /device/:device_id_or_serial_number/validation/:validation_id`

Does not store validation results.

This endpoint is **deprecated** and will be removed in Conch API v4.0.

- User requires the read-only role
- Controller/Action: ["validate" in Conch::Controller::DeviceValidation](../modules/Conch%3A%3AController%3A%3ADeviceValidation#validate)
- Request: [request.json#/definitions/DeviceReport](../json-schema/request.json#/definitions/DeviceReport)
- Response: [response.json#/definitions/ValidationResults](../json-schema/response.json#/definitions/ValidationResults)

### `POST /device/:device_id_or_serial_number/validation_plan/:validation_plan_id`

Does not store validation results.

This endpoint is **deprecated** and will be removed in Conch API v4.0.

- User requires the read-only role
- Controller/Action: ["run\_validation\_plan" in Conch::Controller::DeviceValidation](../modules/Conch%3A%3AController%3A%3ADeviceValidation#run_validation_plan)
- Request: [request.json#/definitions/DeviceReport](../json-schema/request.json#/definitions/DeviceReport)
- Response: [response.json#/definitions/ValidationResults](../json-schema/response.json#/definitions/ValidationResults)

### `GET /device/:device_id_or_serial_number/validation_state?status=<pass|fail|error>&status=...`

Accepts the query parameter `status`, indicating the desired status(es)
to search for (one of `pass`, `fail`, `error`). Can be used more than once.

- User requires the read-only role
- Controller/Action: ["get\_validation\_state" in Conch::Controller::DeviceValidation](../modules/Conch%3A%3AController%3A%3ADeviceValidation#get_validation_state)
- Response: [response.json#/definitions/ValidationStateWithResults](../json-schema/response.json#/definitions/ValidationStateWithResults)

### `GET /device/:device_id_or_serial_number/interface`

- User requires the read-only role
- Controller/Action: ["get\_all" in Conch::Controller::DeviceInterface](../modules/Conch%3A%3AController%3A%3ADeviceInterface#get_all)
- Response: [response.json#/definitions/DeviceNics](../json-schema/response.json#/definitions/DeviceNics)

### `GET /device/:device_id_or_serial_number/interface/:interface_name`

- User requires the read-only role
- Controller/Action: ["get\_one" in Conch::Controller::DeviceInterface](../modules/Conch%3A%3AController%3A%3ADeviceInterface#get_one)
- Response: [response.json#/definitions/DeviceNic](../json-schema/response.json#/definitions/DeviceNic)

### `GET /device/:device_id_or_serial_number/interface/:interface_name/:field`

- User requires the read-only role
- Controller/Action: ["get\_one\_field" in Conch::Controller::DeviceInterface](../modules/Conch%3A%3AController%3A%3ADeviceInterface#get_one_field)
- Response: [response.json#/definitions/DeviceNicField](../json-schema/response.json#/definitions/DeviceNicField)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
