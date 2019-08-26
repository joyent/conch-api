# NAME

Conch::Route::Relay

# METHODS

## routes

Sets up the routes for /relay:

Unless otherwise noted, all routes require authentication.

### `POST /relay/:relay_serial_number/register`

- Request: request.yaml#/RegisterRelay
- Response: `201 CREATED` or `204 NO CONTENT`, plus Location header

### `GET /relay`

- Requires system admin authorization
- Response: response.yaml#/Relays

### `GET /relay/:relay_id_or_serial_number`

- Requires system admin authorization, or the user to have previously registered the relay.
- Response: response.yaml#/Relay

## `DELETE /relay/:relay_id_or_serial_number`

- Requires system admin authorization
- Response: `204 NO CONTENT`

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
