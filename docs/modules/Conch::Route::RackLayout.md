# Conch::Route::RackLayout

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Route/RackLayout.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Route/RackLayout.pm)

## METHODS

### routes

Sets up the routes for /layout.

### one\_layout\_routes

Sets up the routes for working with just one layout, mounted under a provided route prefix.

## ROUTE ENDPOINTS

All routes require authentication.

Take note: All routes that reference a specific rack layout (prefix `/layout/:layout_id`) are
also available under `/rack/:rack_id_or_long_name/layout/:layout_id_or_rack_unit_start` as
well as
`/room/datacenter_room_id_or_alias/rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start`.

### `GET /layout`

- Requires system admin authorization
- Response: [response.json#/definitions/RackLayouts](../json-schema/response.json#/definitions/RackLayouts)

### `POST /layout`

- Requires system admin authorization
- Request: [request.json#/definitions/RackLayoutCreate](../json-schema/request.json#/definitions/RackLayoutCreate)
- Response: Redirect to the created rack layout

### `GET /layout/:layout_id`

- Requires system admin authorization
- Response: [response.json#/definitions/RackLayout](../json-schema/response.json#/definitions/RackLayout)

### `POST /layout/:layout_id`

- Requires system admin authorization
- Request: [request.json#/definitions/RackLayoutUpdate](../json-schema/request.json#/definitions/RackLayoutUpdate)
- Response: Redirect to the update rack layout

### `DELETE /layout/:layout_id`

- Requires system admin authorization
- Response: `204 No Content`

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
