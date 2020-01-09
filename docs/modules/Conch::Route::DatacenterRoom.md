# NAME

Conch::Route::DatacenterRoom

# METHODS

## routes

Sets up the routes for /room:

All routes require authentication.

### `GET /room`

- Requires system admin authorization
- Response: [response.json#/definitions/DatacenterRoomsDetailed](../json-schema/response.json#/definitions/DatacenterRoomsDetailed)

### `POST /room`

- Requires system admin authorization
- Request: [request.json#/definitions/DatacenterRoomCreate](../json-schema/request.json#/definitions/DatacenterRoomCreate)
- Response: Redirect to the created room

### `GET /room/:datacenter_room_id_or_alias`

- User requires system admin authorization, or the read-only role on a rack located in
the room
- Response: [response.json#/definitions/DatacenterRoomDetailed](../json-schema/response.json#/definitions/DatacenterRoomDetailed)

### `POST /room/:datacenter_room_id_or_alias`

- Requires system admin authorization
- Request: [request.json#/definitions/DatacenterRoomUpdate](../json-schema/request.json#/definitions/DatacenterRoomUpdate)
- Response: Redirect to the updated room

### `DELETE /room/:datacenter_room_id_or_alias`

- Requires system admin authorization
- Response: `204 NO CONTENT`

### `GET /room/:datacenter_room_id_or_alias/rack`

- User requires system admin authorization, or the read-only role on a rack located in
the room (in which case data returned is restricted to those racks)
- Response: [response.json#/definitions/Racks](../json-schema/response.json#/definitions/Racks)

### `GET /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name`

- User requires the read-only role on the rack
- Response: [response.json#/definitions/Rack](../json-schema/response.json#/definitions/Rack)

### `POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name`

- User requires the read/write role on the rack
- Request: [request.json#/definitions/RackUpdate](../json-schema/request.json#/definitions/RackUpdate)
- Response: Redirect to the updated rack

### `DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name`

- Requires system admin authorization
- Response: `204 NO CONTENT`

### `GET /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layouts`

- User requires the read-only role on the rack
- Response: [response.json#/definitions/RackLayouts](../json-schema/response.json#/definitions/RackLayouts)

### `POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layouts`

- User requires the read/write role on the rack
- Request: [request.json#/definitions/RackLayouts](../json-schema/request.json#/definitions/RackLayouts)
- Response: Redirect to the rack's layouts

### `GET /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/assignment`

- User requires the read-only role on the rack
- Response: [response.json#/definitions/RackAssignments](../json-schema/response.json#/definitions/RackAssignments)

### `POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/assignment`

- User requires the read/write role on the rack
- Request: [request.json#/definitions/RackAssignmentUpdates](../json-schema/request.json#/definitions/RackAssignmentUpdates)
- Response: Redirect to the updated rack assignment

### `DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/assignment`

This method requires a request body.

- User requires the read/write role on the rack
- Request: [request.json#/definitions/RackAssignmentDeletes](../json-schema/request.json#/definitions/RackAssignmentDeletes)
- Response: `204 NO CONTENT`

### `POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/phase?rack_only=<0|1>`

The query parameter `rack_only` (defaults to `0`) specifies whether to update
only the rack's phase, or all the rack's devices' phases as well.

- User requires the read/write role on the rack
- Request: [request.json#/definitions/RackPhase](../json-schema/request.json#/definitions/RackPhase)
- Response: Redirect to the updated rack

### `GET /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start`

See ["`GET /layout/:layout_id`" in Conch::Route::RackLayout](../modules/Conch%3A%3ARoute%3A%3ARackLayout#get-layoutlayout_id).

### `POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start`

See ["`POST /layout/:layout_id`" in Conch::Route::RackLayout](../modules/Conch%3A%3ARoute%3A%3ARackLayout#post-layoutlayout_id).

### `DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start`

See ["`DELETE /layout/:layout_id`" in Conch::Route::RackLayout](../modules/Conch%3A%3ARoute%3A%3ARackLayout#delete-layoutlayout_id).

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
