# NAME

Conch::Route::RackLayout

# METHODS

## routes

Sets up the routes for /layout:

Unless otherwise noted, all routes require authentication.

### `GET /layout`

- Requires system admin authorization
- Response: response.yaml#/RackLayouts

### `POST /layout`

- Requires system admin authorization
- Request: request.yaml#/RackLayoutCreate
- Response: Redirect to the created rack layout

### `GET /layout/:layout_id`

- Requires system admin authorization
- Response: response.yaml#/RackLayout

### `POST /layout/:layout_id`

- Requires system admin authorization
- Request: request.yaml#/RackLayoutUpdate
- Response: Redirect to the update rack layout

### `DELETE /layout/:layout_id`

- Requires system admin authorization
- Response: `204 NO CONTENT`

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
