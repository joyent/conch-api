# NAME

Conch::Controller::DatacenterRoom

# METHODS

## find\_datacenter\_room

Chainable action that uses the `datacenter_room_id_or_alias` value provided in the stash
(usually via the request URL) to look up a datacenter\_room, and stashes the query to get to it
in `datacenter_room_rs`.

If `require_role` is provided, it is used as the minimum required role for the user to
continue; otherwise the user must be a system admin.

## get\_all

Get all datacenter rooms.

Response uses the DatacenterRoomsDetailed json schema.

## get\_one

Get a single datacenter room.

Response uses the DatacenterRoomDetailed json schema.

## create

Create a new datacenter room.

## update

Update an existing room.

## delete

Permanently delete a datacenter room.

## racks

Response uses the Racks json schema.

## find\_rack

Response uses the Rack json schema.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
