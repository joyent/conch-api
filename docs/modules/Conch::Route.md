# NAME

Conch::Route

# DESCRIPTION

Set up all the routes for the Conch Mojo application.

# METHODS

## all\_routes

Set up the full route structure

Unless otherwise specified, all routes require authentication.

Full access is granted to system admin users, regardless of workspace or other role entries.

Successful (http 2xx code) response structures are as described for each endpoint.

Error responses will use:

- failure to validate query parameters: http 400, [response.json#/definitions/QueryParamsValidationError](../json-schema/response.json#/definitions/QueryParamsValidationError)
- failure to validate request body payload: http 400, [response.json#/RequestValidationError](../json-schema/response.json#/RequestValidationError)
- all other errors, unless specified: http 4xx, [response.json#/Error](../json-schema/response.json#/Error)

### `GET /ping`

- Does not require authentication.
- Response: [response.json#/definitions/Ping](../json-schema/response.json#/definitions/Ping)

### `GET /version`

- Does not require authentication.
- Response: [response.json#/definitions/Version](../json-schema/response.json#/definitions/Version)

### `POST /login`

- Request: [request.json#/definitions/Login](../json-schema/request.json#/definitions/Login)
- Response: [response.json#/definitions/Login](../json-schema/response.json#/definitions/Login)

### `POST /logout`

- Does not require authentication.
- Response: `204 NO CONTENT`

### `GET /schema/query_params/:schema_name`

### `GET /schema/request/:schema_name`

### `GET /schema/response/:schema_name`

Returns the schema specified by type and name.

- Does not require authentication.
- Response: JSON-Schema ([http://json-schema.org/draft-07/schema](http://json-schema.org/draft-07/schema))

### `GET /workspace/:workspace/device-totals`

### `GET /workspace/:workspace/device-totals.circ`

- Does not require authentication.
- Response: [response.json#/definitions/DeviceTotals](../json-schema/response.json#/definitions/DeviceTotals)
- Response (Circonus): [response.json#/definitions/DeviceTotalsCirconus](../json-schema/response.json#/definitions/DeviceTotalsCirconus)

### `POST /refresh_token`

- Request: [request.json#/definitions/Null](../json-schema/request.json#/definitions/Null)
- Response: [response.json#/definitions/Login](../json-schema/response.json#/definitions/Login)

### `* /dc`, `* /room`, `* /rack_role`, `* /rack`, `* /layout`

See ["routes" in Conch::Route::Datacenter](../modules/Conch::Route::Datacenter#routes)

### `* /device`

See ["routes" in Conch::Route::Device](../modules/Conch::Route::Device#routes)

### `* /device_report`

See ["routes" in Conch::Route::DeviceReport](../modules/Conch::Route::DeviceReport#routes)

### `* /hardware_product`

See ["routes" in Conch::Route::HardwareProduct](../modules/Conch::Route::HardwareProduct#routes)

### `* /hardware_vendor`

See ["routes" in Conch::Route::HardwareVendor](../modules/Conch::Route::HardwareVendor#routes)

### `* /organization`

See ["routes" in Conch::Route::Organization](../modules/Conch::Route::Organization#routes)

### `* /relay`

See ["routes" in Conch::Route::Relay](../modules/Conch::Route::Relay#routes)

### `* /schema`

See ["routes" in Conch::Route::Schema](../modules/Conch::Route::Schema#routes)

### `* /user`

See ["routes" in Conch::Route::User](../modules/Conch::Route::User#routes)

### `* /validation`, `* /validation_plan`, `* /validation_state`

See [Conch:Route::Validation/routes](Conch:Route::Validation/routes)

### `* /workspace`

See ["routes" in Conch::Route::Workspace](../modules/Conch::Route::Workspace#routes)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
