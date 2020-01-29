# Conch::Route::Datacenter

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Route/Datacenter.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Route/Datacenter.pm)

## METHODS

### routes

Sets up the routes for /dc.

## ROUTE ENDPOINTS

All routes require authentication.

### `GET /dc`

- Requires system admin authorization
- Response: [response.json#/definitions/Datacenters](../json-schema/response.json#/definitions/Datacenters)

### `POST /dc`

- Requires system admin authorization
- Request: [request.json#/definitions/DatacenterCreate](../json-schema/request.json#/definitions/DatacenterCreate)
- Response: `201 CREATED` or `204 NO CONTENT`, plus Location header

### `GET /dc/:datacenter_id`

- Requires system admin authorization
- Response: [response.json#/definitions/Datacenter](../json-schema/response.json#/definitions/Datacenter)

### `POST /dc/:datacenter_id`

- Requires system admin authorization
- Request: [request.json#/definitions/DatacenterUpdate](../json-schema/request.json#/definitions/DatacenterUpdate)
- Response: Redirect to the updated datacenter

### `DELETE /dc/:datacenter_id`

- Requires system admin authorization
- Response: `204 NO CONTENT`

### `GET /dc/:datacenter_id/rooms`

- Requires system admin authorization
- Response: [response.json#/definitions/DatacenterRoomsDetailed](../json-schema/response.json#/definitions/DatacenterRoomsDetailed)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
