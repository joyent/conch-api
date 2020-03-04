# NAME

Conch::Route::Relay

# METHODS

## routes

Sets up the routes for /relay:

Unless otherwise noted, all routes require authentication.

### `POST /relay/:relay_id/register`

- Request: input.yaml#/RegisterRelay
- Response: `204 NO CONTENT`

### `GET /relay`

- Requires System Admin Authentication
- Response: response.yaml#/Relays

## `DELETE /relay/:relay_serial_number`

- Requires system admin authorization
- Response: `204 NO CONTENT`

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
