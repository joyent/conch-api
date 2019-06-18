# NAME

Conch::Route::Relay

# METHODS

## routes

Sets up the routes for /relay:

Unless otherwise noted, all routes require authentication.

### `POST /relay/:relay_id/register`

- Request: request.yaml#/RegisterRelay
- Response: `204 NO CONTENT`

### `GET /relay`

- Requires system admin authorization
- Response: response.yaml#/Relays

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
