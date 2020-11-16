# Conch::Route

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Route.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Route.pm)

## DESCRIPTION

Set up all the routes for the Conch Mojo application.

## METHODS

### all\_routes

Set up the full route structure

## SHORTCUTS

These are available on all routes. See ["Shortcuts" in Mojolicious::Guides::Routing](https://metacpan.org/pod/Mojolicious%3A%3AGuides%3A%3ARouting#shortcuts).

### require\_system\_admin

Chainable route that aborts with HTTP 403 if the user is not a system admin.

### find\_user\_from\_payload

Chainable route that looks up the user by `user_id` or `email` in the JSON payload,
aborting with HTTP 410 or HTTP 404 if not found.

### root

Returns the root node.

## ROUTE ENDPOINTS

Unless otherwise specified, all routes require authentication.

Full access is granted to system admin users, regardless of build or other role entries.

Successful (HTTP 2xx code) response structures are as described for each endpoint.

Error responses will use:

- failure to validate query parameters: HTTP 400, [response.json#/definitions/QueryParamsValidationError](../json-schema/response.json#/definitions/QueryParamsValidationError)
- failure to validate request body payload: HTTP 400, [response.json#/definitions/RequestValidationError](../json-schema/response.json#/definitions/RequestValidationError)
- all other errors, unless specified: HTTP 4xx, [response.json#/definitions/Error](../json-schema/response.json#/definitions/Error)

### `GET /ping`

- Does not require authentication.
- Response: [response.json#/definitions/Ping](../json-schema/response.json#/definitions/Ping)

### `GET /version`

- Does not require authentication.
- Response: [response.json#/definitions/Version](../json-schema/response.json#/definitions/Version)

### `POST /login`

- Controller/Action: ["login" in Conch::Controller::Login](../modules/Conch%3A%3AController%3A%3ALogin#login)
- Request: [request.json#/definitions/Login](../json-schema/request.json#/definitions/Login)
- Response: [response.json#/definitions/LoginToken](../json-schema/response.json#/definitions/LoginToken)

### `POST /logout`

- Controller/Action: ["logout" in Conch::Controller::Login](../modules/Conch%3A%3AController%3A%3ALogin#logout)
- Request: [request.json#/definitions/Null](../json-schema/request.json#/definitions/Null)
- Response: `204 No Content`

### `POST /refresh_token`

- Controller/Action: ["refresh\_token" in Conch::Controller::Login](../modules/Conch%3A%3AController%3A%3ALogin#refresh_token)
- Request: [request.json#/definitions/Null](../json-schema/request.json#/definitions/Null)
- Response: [response.json#/definitions/LoginToken](../json-schema/response.json#/definitions/LoginToken)

### `GET /me`

- Response: `204 No Content`

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

### `* /json_schema`

See ["unsecured\_routes" in Conch::Route::JSONSchema](../modules/Conch%3A%3ARoute%3A%3AJSONSchema#unsecured_routes)

### `* /user`

See ["routes" in Conch::Route::User](../modules/Conch%3A%3ARoute%3A%3AUser#routes)

### `* /validation_plan`

See ["routes" in Conch::Route::ValidationPlan](../modules/Conch%3A%3ARoute%3A%3AValidationPlan#routes)

### `* /validation_state`

See ["routes" in Conch::Route::ValidationState](../modules/Conch%3A%3ARoute%3A%3AValidationState#routes)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
