# Conch::Route::Relay

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Route/Relay.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Route/Relay.pm)

## METHODS

### routes

Sets up the routes for /relay.

## ROUTE ENDPOINTS

All routes require authentication.

### `POST /relay/:relay_serial_number/register`

- Controller/Action: ["register" in Conch::Controller::Relay](../modules/Conch%3A%3AController%3A%3ARelay#register)
- Request: [request.json#/definitions/RegisterRelay](../json-schema/request.json#/definitions/RegisterRelay)
- Response: `201 Created` or `204 No Content`, plus Location header

### `GET /relay`

- Requires system admin authorization
- Controller/Action: ["get\_all" in Conch::Controller::Relay](../modules/Conch%3A%3AController%3A%3ARelay#get_all)
- Response: [response.json#/definitions/Relays](../json-schema/response.json#/definitions/Relays)

### `GET /relay/:relay_id_or_serial_number`

- Requires system admin authorization, or the user to have previously registered the relay.
- Controller/Action: ["get" in Conch::Controller::Relay](../modules/Conch%3A%3AController%3A%3ARelay#get)
- Response: [response.json#/definitions/Relay](../json-schema/response.json#/definitions/Relay)

### `DELETE /relay/:relay_id_or_serial_number`

- Requires system admin authorization
- Controller/Action: ["delete" in Conch::Controller::Relay](../modules/Conch%3A%3AController%3A%3ARelay#delete)
- Response: `204 No Content`

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
