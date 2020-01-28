# Conch::Route

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Route.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Route.pm)

## DESCRIPTION

Set up all the routes for the Conch Mojo application.

## METHODS

### all\_routes

Set up the full route structure

## SHORTCUTS

These are available on the root router. See ["Shortcuts" in Mojolicious::Guides::Routing](https://metacpan.org/pod/Mojolicious%3A%3AGuides%3A%3ARouting#shortcuts).

### require\_system\_admin

Chainable route that aborts with HTTP 403 if the user is not a system admin.

### find\_user\_from\_payload

Chainable route that looks up the user by `user_id` or `email` in the JSON payload,
aborting with HTTP 410 or HTTP 404 if not found.

## ROUTE ENDPOINTS

Unless otherwise specified, all routes require authentication.

Full access is granted to system admin users, regardless of workspace, build or other role
entries.

Successful (HTTP 2xx code) response structures are as described for each endpoint.

Error responses will use:

- failure to validate query parameters: HTTP 400, [response.json#/definitions/QueryParamsValidationError](../json-schema/response.json#/definitions/QueryParamsValidationError)
- failure to validate request body payload: HTTP 400, [response.json#/RequestValidationError](../json-schema/response.json#/RequestValidationError)
- all other errors, unless specified: HTTP 4xx, [response.json#/Error](../json-schema/response.json#/Error)

### `GET /ping`

- Does not require authentication.
- Response: [response.json#/definitions/Ping](../json-schema/response.json#/definitions/Ping)

### `GET /version`

- Does not require authentication.
- Response: [response.json#/definitions/Version](../json-schema/response.json#/definitions/Version)

### `POST /login`

- Request: [request.json#/definitions/Login](../json-schema/request.json#/definitions/Login)
- Response: [response.json#/definitions/LoginToken](../json-schema/response.json#/definitions/LoginToken)

### `POST /logout`

- Request: [request.json#/definitions/Null](../json-schema/request.json#/definitions/Null)
- Response: `204 NO CONTENT`

### `GET /workspace/:workspace/device-totals`

### `GET /workspace/:workspace/device-totals.circ`

- Does not require authentication.
- Response: [response.json#/definitions/DeviceTotals](../json-schema/response.json#/definitions/DeviceTotals)
- Response (Circonus): [response.json#/definitions/DeviceTotalsCirconus](../json-schema/response.json#/definitions/DeviceTotalsCirconus)

### `POST /refresh_token`

- Request: [request.json#/definitions/Null](../json-schema/request.json#/definitions/Null)
- Response: [response.json#/definitions/LoginToken](../json-schema/response.json#/definitions/LoginToken)

### `* /dc`, `* /room`, `* /rack_role`, `* /rack`, `* /layout`

See ["routes" in Conch::Route::Datacenter](../modules/Conch%3A%3ARoute%3A%3ADatacenter#routes)

### `* /device`

See ["routes" in Conch::Route::Device](../modules/Conch%3A%3ARoute%3A%3ADevice#routes)

### `* /device_report`

See ["routes" in Conch::Route::DeviceReport](../modules/Conch%3A%3ARoute%3A%3ADeviceReport#routes)

### `* /hardware_product`

See ["routes" in Conch::Route::HardwareProduct](../modules/Conch%3A%3ARoute%3A%3AHardwareProduct#routes)

### `* /hardware_vendor`

See ["routes" in Conch::Route::HardwareVendor](../modules/Conch%3A%3ARoute%3A%3AHardwareVendor#routes)

### `* /organization`

See ["routes" in Conch::Route::Organization](../modules/Conch%3A%3ARoute%3A%3AOrganization#routes)

### `* /relay`

See ["routes" in Conch::Route::Relay](../modules/Conch%3A%3ARoute%3A%3ARelay#routes)

### `* /schema`

See ["routes" in Conch::Route::Schema](../modules/Conch%3A%3ARoute%3A%3ASchema#routes)

### `* /user`

See ["routes" in Conch::Route::User](../modules/Conch%3A%3ARoute%3A%3AUser#routes)

### `* /validation`, `* /validation_plan`, `* /validation_state`

See ["routes" in Conch::Route::Validation](../modules/Conch%3A%3ARoute%3A%3AValidation#routes)

### `* /workspace`

See ["routes" in Conch::Route::Workspace](../modules/Conch%3A%3ARoute%3A%3AWorkspace#routes)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
