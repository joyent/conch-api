# Conch::Route::Relay

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Route/Relay.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Route/Relay.pm)

## METHODS

### routes

Sets up the routes for /relay.

## ROUTE ENDPOINTS

All routes require authentication.

### `POST /relay/:relay_serial_number/register`

- Request: [request.json#/definitions/RegisterRelay](../json-schema/request.json#/definitions/RegisterRelay)
- Response: `201 CREATED` or `204 NO CONTENT`, plus Location header

### `GET /relay`

- Requires system admin authorization
- Response: [response.json#/definitions/Relays](../json-schema/response.json#/definitions/Relays)

### `GET /relay/:relay_id_or_serial_number`

- Requires system admin authorization, or the user to have previously registered the relay.
- Response: [response.json#/definitions/Relay](../json-schema/response.json#/definitions/Relay)

### `DELETE /relay/:relay_id_or_serial_number`

- Requires system admin authorization
- Response: `204 NO CONTENT`

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
