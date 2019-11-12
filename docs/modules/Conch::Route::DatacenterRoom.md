# NAME

Conch::Route::DatacenterRoom

# METHODS

## routes

Sets up the routes for /room:

Unless otherwise noted, all routes require authentication.

### `GET /room`

- Requires system admin authorization
- Response: [response.json#/definitions/DatacenterRoomsDetailed](../json-schema/response.json#/definitions/DatacenterRoomsDetailed)

### `POST /room`

- Requires system admin authorization
- Request: [request.json#/definitions/DatacenterRoomCreate](../json-schema/request.json#/definitions/DatacenterRoomCreate)
- Response: Redirect to the created room

### `GET /room/:datacenter_room_id_or_alias`

- Requires system admin authorization
- Response: [response.json#/definitions/DatacenterRoomDetailed](../json-schema/response.json#/definitions/DatacenterRoomDetailed)

### `POST /room/:datacenter_room_id_or_alias`

- Requires system admin authorization
- Request: [request.json#/definitions/DatacenterRoomUpdate](../json-schema/request.json#/definitions/DatacenterRoomUpdate)
- Response: Redirect to the updated room

### `DELETE /room/:datacenter_room_id_or_alias`

- Requires system admin authorization
- Response: `204 NO CONTENT`

### `GET /room/:datacenter_room_id_or_alias/racks`

- Requires system admin authorization
- Response: [response.json#/definitions/Racks](../json-schema/response.json#/definitions/Racks)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
