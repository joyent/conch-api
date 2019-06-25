# NAME

Conch::Route::Datacenter

# METHODS

## routes

Sets up the routes for /dc, /room, /rack\_role, /rack and /layout:

Unless otherwise noted, all routes require authentication.

### `GET /dc`

- Requires system admin authorization
- Response: response.yaml#/Datacenters

### `POST /dc`

- Requires system admin authorization
- Request: request.yaml#/DatacenterCreate
- Response: Redirect to the created datacenter

### `GET /dc/:datacenter_id`

- Requires system admin authorization
- Response: response.yaml#/Datacenter

### `POST /dc/:datacenter_id`

- Requires system admin authorization
- Request: request.yaml#/DatacenterUpdate
- Response: Redirect to the updated datacenter

### `DELETE /dc/:datacenter_id`

- Requires system admin authorization
- Response: `204 NO CONTENT`

### `GET /dc/:datacenter_id/rooms`

- Requires system admin authorization
- Response: response.yaml#/DatacenterRoomsDetailed

### `GET /room`

- Requires system admin authorization
- Response: response.yaml#/DatacenterRoomsDetailed

### `POST /room`

- Requires system admin authorization
- Request: request.yaml#/DatacenterRoomCreate
- Response: Redirect to the created room

### `GET /room/:datacenter_room_id`

- Requires system admin authorization
- Response: response.yaml#/DatacenterRoomDetailed

### `POST /room/:datacenter_room_id`

- Requires system admin authorization
- Request: request.yaml#/DatacenterRoomUpdate
- Response: Redirect to the updated room

### `DELETE /room/:datacenter_room_id`

- Requires system admin authorization
- Response: `204 NO CONTENT`

### `GET /room/:datacenter_room_id/racks`

- Requires system admin authorization
- Response: response.yaml#/Racks

### `GET /rack_role`

- Requires system admin authorization
- Response: response.yaml#/RackRoles

### `POST /rack_role`

- Requires system admin authorization
- Request: request.yaml#/RackRoleCreate
- Response: Redirect to the created rack role

### `GET /rack_role/:rack_role_id_or_name`

- Requires system admin authorization
- Response: response.yaml#/RackRole

### `POST /rack_role/:rack_role_id_or_name`

- Requires system admin authorization
- Request: request.yaml#/RackRoleUpdate
- Response: Redirect to the updated rack role

### `DELETE /rack_role/:rack_role_id_or_name`

- Requires system admin authorization
- Response: `204 NO CONTENT`

### `GET /rack`

- Requires system admin authorization
- Response: response.yaml#/Racks

### `POST /rack`

- Requires system admin authorization
- Request: request.yaml#/RackCreate
- Response: Redirect to the created rack

### `GET /rack/:rack_id`

- User requires the read-only role on a workspace that contains the rack
- Response: response.yaml#/Rack

### `POST /rack/:rack_id`

- User requires the read/write role on a workspace that contains the rack
- Request: request.yaml#/RackUpdate
- Response: Redirect to the updated rack

### `DELETE /rack/:rack_id`

- User requires the read/write role on a workspace that contains the rack
- Response: `204 NO CONTENT`

### `GET /rack/:rack_id/layouts`

- User requires the read-only role on a workspace that contains the rack
- Response: response.yaml#/RackLayouts

### `GET /rack/:rack_id/assignment`

- User requires the read-only role on a workspace that contains the rack
- Response: response.yaml#/RackAssignments

### `POST /rack/:rack_id/assignment`

- User requires the read/write role on a workspace that contains the rack
- Request: request.yaml#/RackAssignmentUpdates
- Response: Redirect to the updated rack assignment

### `DELETE /rack/:rack_id/assignment`

This method requires a request body.

- User requires the read/write role on a workspace that contains the rack
- Request: request.yaml#/RackAssignmentDeletes
- Response: `204 NO CONTENT`

### `POST /rack/:rack_id/phase?rack_only=<0|1>`

The query parameter `rack_only` (defaults to `0`) specifies whether to update
only the rack's phase, or all the rack's devices' phases as well.

- User requires the read/write role on a workspace that contains the rack
- Request: request.yaml#/RackPhase
- Response: Redirect to the updated rack

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
