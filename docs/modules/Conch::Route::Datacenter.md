# NAME

Conch::Route::Datacenter

# METHODS

## routes

Sets up the routes for /dc, /room, /rack\_role, /rack and /layout:

Unless otherwise noted, all routes require authentication.

### `GET /dc`

- Response: response.yaml#/Datacenters

### `POST /dc`

- Request: input.yaml#/DatacenterCreate
- Response: Redirect to the created datacenter

### `GET /dc/:datacenter_id`

- Response: response.yaml#/Datacenter

### `POST /dc/:datacenter_id`

- Request: input.yaml#/DatacenterUpdate
- Response: Redirect to the updated datacenter

### `DELETE /dc/:datacenter_id`

- Response: `204 NO CONTENT`

### `GET /dc/:datacenter_id/rooms`

- Requires System Admin Authorization
- Response: response.yaml#/DatacenterRoomsDetailed

### `GET /room`

- Requires System Admin Authorization
- Response: response.yaml#/DatacenterRoomsDetailed

### `POST /room`

- Requires System Admin Authorization
- Request: input.yaml#/DatacenterRoomCreate
- Response: Redirect to the created room

### `GET /room/:datacenter_room_id`

- Requires System Admin Authorization
- Response: response.yaml#/DatacenterRoomDetailed

### `POST /room/:datacenter_room_id`

- Requires System Admin Authorization
- Request: input.yaml#/DatacenterRoomUpdate
- Response: Redirect to the updated room

### `DELETE /room/:datacenter_room_id`

- Requires System Admin Authorization
- Response: `204 NO CONTENT`

### `GET /room/:datacenter_room_id/racks`

- Requires System Admin Authorization
- Response: response.yaml#/Racks

### `GET /rack_role`

- Requires System Admin Authorization
- Response: response.yaml#/RackRoles

### `POST /rack_role`

- Requires System Admin Authorization
- Request: input.yaml#/RackRoleCreate
- Response: Redirect to the created rack role

### `GET /rack_role/:rack_role_id_or_name`

- Requires System Admin Authorization
- Response: response.yaml#/RackRole

### `POST /rack_role/:rack_role_id_or_name`

- Request: input.yaml#/RackRoleUpdate
- Response: Redirect to the updated rack role

### `DELETE /rack_role/:rack_role_id_or_name`

- Response: `204 NO CONTENT`

### `GET /rack`

- Requires System Admin Authentication
- Response: response.yaml#/Racks

### `POST /rack`

- Requires System Admin Authentication
- Request: input.yaml#/RackCreate
- Response: Redirect to the created rack

### `GET /rack/:rack_id`

- Response: response.yaml#/Rack

### `POST /rack/:rack_id`

- Request: input.yaml#/RackUpdate
- Response: Redirect to the updated rack

### `DELETE /rack/:rack_id`

- Response: `204 NO CONTENT`

### `GET /rack/:rack_id/layouts`

- Response: response.yaml#/RackLayouts

### `GET /rack/:rack_id/assignment`

- Response: response.yaml#/RackAssignments

### `POST /rack/:rack_id/assignment`

- Request: input.yaml#/RackAssignmentUpdates
- Response: Redirect to the updated rack assignment

### `DELETE /rack/:rack_id/assignment`

This method requires a request body.

- Request: input.yaml#/RackAssignmentDeletes
- Response: `204 NO CONTENT`

### `POST /rack/:rack_id/phase?rack_only=<0|1>`

The query parameter `rack_only` (default 0) specifies whether to update
only the rack's phase, or all the rack's devices' phases as well.

- Request: input.yaml#/RackPhase
- Response: `204 NO CONTENT`

### `GET /layout`

- Response: response.yaml#/RackLayouts

### `POST /layout`

- Requires Admin Authentication
- Request: input.yaml#/RackLayoutCreate
- Response: Redirect to the created rack layout

### `GET /layout/:layout_id`

- Response: response.yaml#/RackLayout

### `POST /layout/:layout_id`

- Request: input.yaml#/RackLayoutUpdate
- Response: Redirect to the update rack layout

### `DELETE /layout/:layout_id`

- Response: `204 NO CONTENT`

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
