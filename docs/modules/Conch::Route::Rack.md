# NAME

Conch::Route::Rack

# METHODS

## routes

Sets up the routes for /rack:

Unless otherwise noted, all routes require authentication.

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

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
