# Conch::Route::Datacenter

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/Datacenter.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/Datacenter.pm)

## METHODS

### routes

Sets up the routes for /dc.

## ROUTE ENDPOINTS

All routes require authentication.

### `GET /dc`

- Requires system admin authorization
- Controller/Action: ["get\_all" in Conch::Controller::Datacenter](../modules/Conch%3A%3AController%3A%3ADatacenter#get_all)
- Response: [response.json#/$defs/Datacenters](../json-schema/response.json#/$defs/Datacenters)

### `POST /dc`

- Requires system admin authorization
- Controller/Action: ["create" in Conch::Controller::Datacenter](../modules/Conch%3A%3AController%3A%3ADatacenter#create)
- Request: [request.json#/$defs/DatacenterCreate](../json-schema/request.json#/$defs/DatacenterCreate)
- Response: `201 Created` or `204 No Content`, plus Location header

### `GET /dc/:datacenter_id`

- Requires system admin authorization
- Controller/Action: ["get\_one" in Conch::Controller::Datacenter](../modules/Conch%3A%3AController%3A%3ADatacenter#get_one)
- Response: [response.json#/$defs/Datacenter](../json-schema/response.json#/$defs/Datacenter)

### `POST /dc/:datacenter_id`

- Requires system admin authorization
- Controller/Action: ["update" in Conch::Controller::Datacenter](../modules/Conch%3A%3AController%3A%3ADatacenter#update)
- Request: [request.json#/$defs/DatacenterUpdate](../json-schema/request.json#/$defs/DatacenterUpdate)
- Response: Redirect to the updated datacenter

### `DELETE /dc/:datacenter_id`

- Requires system admin authorization
- Controller/Action: ["delete" in Conch::Controller::Datacenter](../modules/Conch%3A%3AController%3A%3ADatacenter#delete)
- Response: `204 No Content`

### `GET /dc/:datacenter_id/rooms`

- Requires system admin authorization
- Controller/Action: ["get\_rooms" in Conch::Controller::Datacenter](../modules/Conch%3A%3AController%3A%3ADatacenter#get_rooms)
- Response: [response.json#/$defs/DatacenterRoomsDetailed](../json-schema/response.json#/$defs/DatacenterRoomsDetailed)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
