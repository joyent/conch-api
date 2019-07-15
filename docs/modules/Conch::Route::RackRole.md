# NAME

Conch::Route::RackRole

# METHODS

## routes

Sets up the routes for /rack\_role:

Unless otherwise noted, all routes require authentication.

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

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
