# NAME

Conch::Route::Datacenter

# METHODS

## routes

Sets up the routes for /dc:

Unless otherwise noted, all routes require authentication.

### `GET /dc`

- Requires system admin authorization
- Response: response.yaml#/Datacenters

### `POST /dc`

- Requires system admin authorization
- Request: request.yaml#/DatacenterCreate
- Response: `201 CREATED` or `204 NO CONTENT`, plus Location header

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

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
