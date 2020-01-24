# Conch::Route::RackRole

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Route/RackRole.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Route/RackRole.pm)

## METHODS

### routes

Sets up the routes for /rack\_role.

## ROUTE ENDPOINTS

All routes require authentication.

### `GET /rack_role`

- Response: [response.json#/definitions/RackRoles](../json-schema/response.json#/definitions/RackRoles)

### `POST /rack_role`

- Requires system admin authorization
- Request: [request.json#/definitions/RackRoleCreate](../json-schema/request.json#/definitions/RackRoleCreate)
- Response: Redirect to the created rack role

### `GET /rack_role/:rack_role_id_or_name`

- Response: [response.json#/definitions/RackRole](../json-schema/response.json#/definitions/RackRole)

### `POST /rack_role/:rack_role_id_or_name`

- Requires system admin authorization
- Request: [request.json#/definitions/RackRoleUpdate](../json-schema/request.json#/definitions/RackRoleUpdate)
- Response: Redirect to the updated rack role

### `DELETE /rack_role/:rack_role_id_or_name`

- Requires system admin authorization
- Response: `204 NO CONTENT`

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
