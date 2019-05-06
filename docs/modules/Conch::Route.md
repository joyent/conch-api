# NAME

Conch::Route

# DESCRIPTION

Set up all the routes for the Conch Mojo application.

# METHODS

## all\_routes

Set up the full route structure

Unless otherwise specified all routes require authentication.

### `/doc`

- Does not require authentication.

### `GET /ping`

- Does not require authentication.
- Response: response.yaml#/Ping

### `GET /version`

- Does not require authentication.
- Response: response.yaml#/Version

### `POST /login`

- Request: input.yaml#/Login
- Response: response.yaml#/Login

### `POST /logout`

- Does not require authentication.
- Response: `204 NO CONTENT`

### `GET /schema/request/:schema_name`

### `GET /schema/response/:schema_name`

Returns the Request or Response schema specified.

- Does not require authentication.
- Response: JSON-Schema ([http://json-schema.org/draft-07/schema](http://json-schema.org/draft-07/schema))

### `GET /workspace/:workspace/device-totals`

### `GET /workspace/:workspace/device-totals.circ`

- Does not require authentication.
- Response: response.yaml#/DeviceTotals
- Response (Circonus): response.yaml#/DeviceTotalsCirconus

### `POST /refresh_token`

- Request: input.yaml#/Null
- Response: response.yaml#/Login

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
