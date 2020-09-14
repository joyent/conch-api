# Conch::Route::DatacenterRoom

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/DatacenterRoom.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/DatacenterRoom.pm)

## METHODS

### routes

Sets up the routes for /room.

All routes require authentication.

## ROUTE ENDPOINTS

### `GET /room`

- Requires system admin authorization
- Controller/Action: ["get\_all" in Conch::Controller::DatacenterRoom](../modules/Conch%3A%3AController%3A%3ADatacenterRoom#get_all)
- Response: [response.json#/$defs/DatacenterRoomsDetailed](../json-schema/response.json#/$defs/DatacenterRoomsDetailed)

### `POST /room`

- Requires system admin authorization
- Controller/Action: ["create" in Conch::Controller::DatacenterRoom](../modules/Conch%3A%3AController%3A%3ADatacenterRoom#create)
- Request: [request.json#/$defs/DatacenterRoomCreate](../json-schema/request.json#/$defs/DatacenterRoomCreate)
- Response: Redirect to the created room

### `GET /room/:datacenter_room_id_or_alias`

- User requires system admin authorization, or the read-only role on a rack located in
the room
- Controller/Action: ["get\_one" in Conch::Controller::DatacenterRoom](../modules/Conch%3A%3AController%3A%3ADatacenterRoom#get_one)
- Response: [response.json#/$defs/DatacenterRoomDetailed](../json-schema/response.json#/$defs/DatacenterRoomDetailed)

### `POST /room/:datacenter_room_id_or_alias`

- Requires system admin authorization
- Controller/Action: ["update" in Conch::Controller::DatacenterRoom](../modules/Conch%3A%3AController%3A%3ADatacenterRoom#update)
- Request: [request.json#/$defs/DatacenterRoomUpdate](../json-schema/request.json#/$defs/DatacenterRoomUpdate)
- Response: Redirect to the updated room

### `DELETE /room/:datacenter_room_id_or_alias`

- Requires system admin authorization
- Controller/Action: ["delete" in Conch::Controller::DatacenterRoom](../modules/Conch%3A%3AController%3A%3ADatacenterRoom#delete)
- Response: `204 No Content`

### `GET /room/:datacenter_room_id_or_alias/rack`

- User requires system admin authorization, or the read-only role on a rack located in
the room (in which case data returned is restricted to those racks)
- Controller/Action: ["racks" in Conch::Controller::DatacenterRoom](../modules/Conch%3A%3AController%3A%3ADatacenterRoom#racks)
- Response: [response.json#/$defs/Racks](../json-schema/response.json#/$defs/Racks)

### `GET /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name`

See ["`GET /rack/:rack_id_or_name`" in Conch::Route::Rack](../modules/Conch%3A%3ARoute%3A%3ARack#get-rackrack_id_or_name).

### `POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name`

See ["`POST /rack/:rack_id_or_name`" in Conch::Route::Rack](../modules/Conch%3A%3ARoute%3A%3ARack#post-rackrack_id_or_name).

### `DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name`

See ["`DELETE /rack/:rack_id_or_name`" in Conch::Route::Rack](../modules/Conch%3A%3ARoute%3A%3ARack#delete-rackrack_id_or_name).

### `GET /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layout`

See ["`GET /rack/:rack_id_or_name/layout`" in Conch::Route::Rack](../modules/Conch%3A%3ARoute%3A%3ARack#get-rackrack_id_or_namelayout).

### `POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layout`

See ["`POST /rack/:rack_id_or_name/layout`" in Conch::Route::Rack](../modules/Conch%3A%3ARoute%3A%3ARack#post-rackrack_id_or_namelayout).

### `GET /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/assignment`

See ["`GET /rack/:rack_id_or_name/assignment`" in Conch::Route::Rack](../modules/Conch%3A%3ARoute%3A%3ARack#get-rackrack_id_or_nameassignment).

### `POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/assignment`

See ["`POST /rack/:rack_id_or_name/assignment`" in Conch::Route::Rack](../modules/Conch%3A%3ARoute%3A%3ARack#post-rackrack_id_or_nameassignment).

### `DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/assignment`

See ["`DELETE /rack/:rack_id_or_name/assignment`" in Conch::Route::Rack](../modules/Conch%3A%3ARoute%3A%3ARack#delete-rackrack_id_or_nameassignment).

### `POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/phase?rack_only=<0|1>`

See ["POST /rack/:rack\_id\_or\_name/phase?rack\_only=01" in Conch::Route::Rack](../modules/Conch%3A%3ARoute%3A%3ARack#post-rackrack_id_or_namephaserack_only01).

### `POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/links`

See ["POST /rack/:rack\_id\_or\_name/links" in Conch::Route::Rack](../modules/Conch%3A%3ARoute%3A%3ARack#post-rackrack_id_or_namelinks).

### `DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/links`

See ["DELETE /rack/:rack\_id\_or\_name/links" in Conch::Route::Rack](../modules/Conch%3A%3ARoute%3A%3ARack#delete-rackrack_id_or_namelinks).

### `GET /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start`

See ["`GET /layout/:layout_id`" in Conch::Route::RackLayout](../modules/Conch%3A%3ARoute%3A%3ARackLayout#get-layoutlayout_id).

### `POST /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start`

See ["`POST /layout/:layout_id`" in Conch::Route::RackLayout](../modules/Conch%3A%3ARoute%3A%3ARackLayout#post-layoutlayout_id).

### `DELETE /room/:datacenter_room_id_or_alias/rack/:rack_id_or_name/layout/:layout_id_or_rack_unit_start`

See ["`DELETE /layout/:layout_id`" in Conch::Route::RackLayout](../modules/Conch%3A%3ARoute%3A%3ARackLayout#delete-layoutlayout_id).

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
