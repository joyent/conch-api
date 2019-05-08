# NAME

Conch::Route::Datacenter

# METHODS

## routes

Sets up the routes for /dc, /room, /rack\_role, /rack and /layout:

```
GET     /dc
POST    /dc
GET     /dc/:datacenter_id
POST    /dc/:datacenter_id
DELETE  /dc/:datacenter_id
GET     /dc/:datacenter_id/rooms

GET     /room
POST    /room
GET     /room/:datacenter_room_id
POST    /room/:datacenter_room_id
DELETE  /room/:datacenter_room_id
GET     /room/:datacenter_room_id/racks

GET     /rack_role
POST    /rack_role
GET     /rack_role/:rack_role_id_or_name
POST    /rack_role/:rack_role_id_or_name
DELETE  /rack_role/:rack_role_id_or_name

GET     /rack
POST    /rack
GET     /rack/:rack_id
POST    /rack/:rack_id
DELETE  /rack/:rack_id
GET     /rack/:rack_id/layouts
GET     /rack/:rack_id/assignment
POST    /rack/:rack_id/assignment
DELETE  /rack/:rack_id/assignment
POST    /rack/:rack_id/phase?rack_only=<0|1>

GET     /layout
POST    /layout
GET     /layout/:layout_id
POST    /layout/:layout_id
DELETE  /layout/:layout_id
```

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
