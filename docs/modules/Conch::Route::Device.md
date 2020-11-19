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
build), and the rack location of the device and the build the rack is contained in (where users
are assigned a [role](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AUserBuildRole#role) in that build).

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
- Response: [response.json#/$defs/Devices](../json-schema/response.json#/$defs/Devices)

### `GET /device/:device_id_or_serial_number`

- User requires the read-only role
- Controller/Action: ["get" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#get)
- Response: [response.json#/$defs/DetailedDevice](../json-schema/response.json#/$defs/DetailedDevice)

### `GET /device/:device_id_or_serial_number/pxe`

- User requires the read-only role
- Controller/Action: ["get\_pxe" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#get_pxe)
- Response: [response.json#/$defs/DevicePXE](../json-schema/response.json#/$defs/DevicePXE)

### `GET /device/:device_id_or_serial_number/phase`

- User requires the read-only role
- Controller/Action: ["get\_phase" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#get_phase)
- Response: [response.json#/$defs/DevicePhase](../json-schema/response.json#/$defs/DevicePhase)

### `GET /device/:device_id_or_serial_number/sku`

- User requires the read-only role
- Controller/Action: ["get\_sku" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#get_sku)
- Response: [response.json#/$defs/DeviceSku](../json-schema/response.json#/$defs/DeviceSku)

### `POST /device/:device_id_or_serial_number/asset_tag`

- User requires the read/write role
- Controller/Action: ["set\_asset\_tag" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#set_asset_tag)
- Request: [request.json#/$defs/DeviceAssetTag](../json-schema/request.json#/$defs/DeviceAssetTag)
- Response: Redirect to the updated device

### `POST /device/:device_id_or_serial_number/validated`

- User requires the read/write role
- Controller/Action: ["set\_validated" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#set_validated)
- Request: [request.json#/$defs/Null](../json-schema/request.json#/$defs/Null)
- Response: Redirect to the updated device

### `POST /device/:device_id_or_serial_number/phase`

- User requires the read/write role
- Controller/Action: ["set\_phase" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#set_phase)
- Request: [request.json#/$defs/DevicePhase](../json-schema/request.json#/$defs/DevicePhase)
- Response: Redirect to the updated device

### `POST /device/:device_id_or_serial_number/links`

- User requires the read/write role
- Controller/Action: ["add\_links" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#add_links)
- Request: [request.json#/$defs/DeviceLinks](../json-schema/request.json#/$defs/DeviceLinks)
- Response: Redirect to the updated device

### `DELETE /device/:device_id_or_serial_number/links`

- User requires the read/write role
- Controller/Action: ["remove\_links" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#remove_links)
- Request: [request.json#/$defs/DeviceLinksOrNull](../json-schema/request.json#/$defs/DeviceLinksOrNull)
- Response: 204 No Content

### `POST /device/:device_id_or_serial_number/build`

- User requires the read/write role for the device, as well as the old and new builds
- Controller/Action: ["set\_build" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#set_build)
- Request: [request.json#/$defs/DeviceBuild](../json-schema/request.json#/$defs/DeviceBuild)
- Response: Redirect to the updated device

### `POST /device/:device_id_or_serial_number/hardware_product`

### `POST /device/:device_id_or_serial_number/sku`

- User requires the admin role for the device
- Controller/Action: ["set\_hardware\_product" in Conch::Controller::Device](../modules/Conch%3A%3AController%3A%3ADevice#set_hardware_product)
- Request: [request.json#/$defs/DeviceHardware](../json-schema/request.json#/$defs/DeviceHardware)
- Response: Redirect to the updated device

### `GET /device/:device_id_or_serial_number/location`

- User requires the read-only role
- Controller/Action: ["get" in Conch::Controller::DeviceLocation](../modules/Conch%3A%3AController%3A%3ADeviceLocation#get)
- Response: [response.json#/$defs/DeviceLocation](../json-schema/response.json#/$defs/DeviceLocation)

### `POST /device/:device_id_or_serial_number/location`

- User requires the read/write role
- Controller/Action: ["set" in Conch::Controller::DeviceLocation](../modules/Conch%3A%3AController%3A%3ADeviceLocation#set)
- Request: [request.json#/$defs/DeviceLocationUpdate](../json-schema/request.json#/$defs/DeviceLocationUpdate)
- Response: Redirect to the updated device

### `DELETE /device/:device_id_or_serial_number/location`

- User requires the read/write role
- Controller/Action: ["delete" in Conch::Controller::DeviceLocation](../modules/Conch%3A%3AController%3A%3ADeviceLocation#delete)
- Response: `204 No Content`

### `GET /device/:device_id_or_serial_number/settings`

- User requires the read-only role
- Controller/Action: ["get\_all" in Conch::Controller::DeviceSettings](../modules/Conch%3A%3AController%3A%3ADeviceSettings#get_all)
- Response: [response.json#/$defs/DeviceSettings](../json-schema/response.json#/$defs/DeviceSettings)

### `POST /device/:device_id_or_serial_number/settings`

- User requires the read/write role, or admin when overwriting existing
settings that do not start with `tag.`.
- Controller/Action: ["set\_all" in Conch::Controller::DeviceSettings](../modules/Conch%3A%3AController%3A%3ADeviceSettings#set_all)
- Request: [request.json#/$defs/DeviceSettings](../json-schema/request.json#/$defs/DeviceSettings)
- Response: `204 No Content`

### `GET /device/:device_id_or_serial_number/settings/:key`

- User requires the read-only role
- Controller/Action: ["get\_single" in Conch::Controller::DeviceSettings](../modules/Conch%3A%3AController%3A%3ADeviceSettings#get_single)
- Response: [response.json#/$defs/DeviceSetting](../json-schema/response.json#/$defs/DeviceSetting)

### `POST /device/:device_id_or_serial_number/settings/:key`

- User requires the read/write role, or admin when overwriting existing
settings that do not start with `tag.`.
- Controller/Action: ["set\_single" in Conch::Controller::DeviceSettings](../modules/Conch%3A%3AController%3A%3ADeviceSettings#set_single)
- Request: [request.json#/$defs/DeviceSettings](../json-schema/request.json#/$defs/DeviceSettings)
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
- Request: [request.json#/$defs/DeviceReport](../json-schema/request.json#/$defs/DeviceReport)
- Response: [response.json#/$defs/LegacyValidationResults](../json-schema/response.json#/$defs/LegacyValidationResults)

### `POST /device/:device_id_or_serial_number/validation_plan/:validation_plan_id`

Does not store validation results.

This endpoint is **deprecated** and will be removed in Conch API v4.0.

- User requires the read-only role
- Controller/Action: ["run\_validation\_plan" in Conch::Controller::DeviceValidation](../modules/Conch%3A%3AController%3A%3ADeviceValidation#run_validation_plan)
- Request: [request.json#/$defs/DeviceReport](../json-schema/request.json#/$defs/DeviceReport)
- Response: [response.json#/$defs/LegacyValidationResults](../json-schema/response.json#/$defs/LegacyValidationResults)

### `GET /device/:device_id_or_serial_number/validation_state?status=<pass|fail|error>&status=...`

Accepts the query parameter `status`, indicating the desired status(es)
to search for (one of `pass`, `fail`, `error`). Can be used more than once.

- User requires the read-only role
- Controller/Action: ["get\_validation\_state" in Conch::Controller::DeviceValidation](../modules/Conch%3A%3AController%3A%3ADeviceValidation#get_validation_state)
- Response: [response.json#/$defs/ValidationStateWithResults](../json-schema/response.json#/$defs/ValidationStateWithResults)

### `GET /device/:device_id_or_serial_number/interface`

- User requires the read-only role
- Controller/Action: ["get\_all" in Conch::Controller::DeviceInterface](../modules/Conch%3A%3AController%3A%3ADeviceInterface#get_all)
- Response: [response.json#/$defs/DeviceNics](../json-schema/response.json#/$defs/DeviceNics)

### `GET /device/:device_id_or_serial_number/interface/:interface_name`

- User requires the read-only role
- Controller/Action: ["get\_one" in Conch::Controller::DeviceInterface](../modules/Conch%3A%3AController%3A%3ADeviceInterface#get_one)
- Response: [response.json#/$defs/DeviceNic](../json-schema/response.json#/$defs/DeviceNic)

### `GET /device/:device_id_or_serial_number/interface/:interface_name/:field`

- User requires the read-only role
- Controller/Action: ["get\_one\_field" in Conch::Controller::DeviceInterface](../modules/Conch%3A%3AController%3A%3ADeviceInterface#get_one_field)
- Response: [response.json#/$defs/DeviceNicField](../json-schema/response.json#/$defs/DeviceNicField)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
