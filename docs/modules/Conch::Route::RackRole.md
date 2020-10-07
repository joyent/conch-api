# Conch::Route::RackRole

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/RackRole.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/RackRole.pm)

## METHODS

### routes

Sets up the routes for /rack\_role.

## ROUTE ENDPOINTS

All routes require authentication.

### `GET /rack_role`

- Controller/Action: ["get\_all" in Conch::Controller::RackRole](../modules/Conch%3A%3AController%3A%3ARackRole#get_all)
- Response: [response.json#/definitions/RackRoles](../json-schema/response.json#/definitions/RackRoles)

### `POST /rack_role`

- Requires system admin authorization
- Controller/Action: ["create" in Conch::Controller::RackRole](../modules/Conch%3A%3AController%3A%3ARackRole#create)
- Request: [request.json#/definitions/RackRoleCreate](../json-schema/request.json#/definitions/RackRoleCreate)
- Response: Redirect to the created rack role

### `GET /rack_role/:rack_role_id_or_name`

- Controller/Action: ["get" in Conch::Controller::RackRole](../modules/Conch%3A%3AController%3A%3ARackRole#get)
- Response: [response.json#/definitions/RackRole](../json-schema/response.json#/definitions/RackRole)

### `POST /rack_role/:rack_role_id_or_name`

- Requires system admin authorization
- Controller/Action: ["update" in Conch::Controller::RackRole](../modules/Conch%3A%3AController%3A%3ARackRole#update)
- Request: [request.json#/definitions/RackRoleUpdate](../json-schema/request.json#/definitions/RackRoleUpdate)
- Response: Redirect to the updated rack role

### `DELETE /rack_role/:rack_role_id_or_name`

- Requires system admin authorization
- Controller/Action: ["delete" in Conch::Controller::RackRole](../modules/Conch%3A%3AController%3A%3ARackRole#delete)
- Response: `204 No Content`

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
