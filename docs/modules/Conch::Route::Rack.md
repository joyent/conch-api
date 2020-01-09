# NAME

Conch::Route::Rack

# METHODS

## routes

Sets up the routes for /rack:

## one\_rack\_routes

Sets up the routes for working with just one rack, mounted under a provided route prefix.

All routes require authentication.

Take note: All routes that reference a specific rack (prefix `/rack/:rack_id`) are also
available under `/rack/:rack_id_or_long_name` as well as
`/room/datacenter_room_id_or_alias/rack/:rack_id_or_name`.

### `POST /rack`

- Requires system admin authorization
- Request: [request.json#/definitions/RackCreate](../json-schema/request.json#/definitions/RackCreate)
- Response: Redirect to the created rack

### `GET /rack/:rack_id_or_name`

- User requires the read-only role on the rack
- Response: [response.json#/definitions/Rack](../json-schema/response.json#/definitions/Rack)

### `POST /rack/:rack_id_or_name`

- User requires the read/write role on the rack
- Request: [request.json#/definitions/RackUpdate](../json-schema/request.json#/definitions/RackUpdate)
- Response: Redirect to the updated rack

### `DELETE /rack/:rack_id_or_name`

- Requires system admin authorization
- Response: `204 NO CONTENT`

### `GET /rack/:rack_id_or_name/layout`

- User requires the read-only role on the rack
- Response: [response.json#/definitions/RackLayouts](../json-schema/response.json#/definitions/RackLayouts)

### `POST /rack/:rack_id_or_name/layout`

- User requires the read/write role on the rack
- Request: [request.json#/definitions/RackLayouts](../json-schema/request.json#/definitions/RackLayouts)
- Response: Redirect to the rack's layouts

### `GET /rack/:rack_id_or_name/assignment`

- User requires the read-only role on the rack
- Response: [response.json#/definitions/RackAssignments](../json-schema/response.json#/definitions/RackAssignments)

### `POST /rack/:rack_id_or_name/assignment`

- User requires the read/write role on the rack
- Request: [request.json#/definitions/RackAssignmentUpdates](../json-schema/request.json#/definitions/RackAssignmentUpdates)
- Response: Redirect to the updated rack assignment

### `DELETE /rack/:rack_id_or_name/assignment`

This method requires a request body.

- User requires the read/write role on the rack
- Request: [request.json#/definitions/RackAssignmentDeletes](../json-schema/request.json#/definitions/RackAssignmentDeletes)
- Response: `204 NO CONTENT`

### `POST /rack/:rack_id_or_name/phase?rack_only=<0|1>`

The query parameter `rack_only` (defaults to `0`) specifies whether to update
only the rack's phase, or all the rack's devices' phases as well.

- User requires the read/write role on the rack
- Request: [request.json#/definitions/RackPhase](../json-schema/request.json#/definitions/RackPhase)
- Response: Redirect to the updated rack

### `GET /rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start`

See ["`GET /layout/:layout_id`" in Conch::Route::RackLayout](../modules/Conch%3A%3ARoute%3A%3ARackLayout#GET-layout-:layout_id).

### `POST /rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start`

See ["`POST /layout/:layout_id`" in Conch::Route::RackLayout](../modules/Conch%3A%3ARoute%3A%3ARackLayout#POST-layout-:layout_id).

### `DELETE /rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start`

See ["`DELETE /layout/:layout_id`" in Conch::Route::RackLayout](../modules/Conch%3A%3ARoute%3A%3ARackLayout#DELETE-layout-:layout_id).

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
