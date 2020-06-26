# Conch::DB::ResultSet::Rack

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/ResultSet/Rack.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/ResultSet/Rack.pm)

## DESCRIPTION

Interface to queries involving racks.

## METHODS

### assigned\_rack\_units

Returns a list of rack\_unit positions that are assigned to current layouts (including positions
assigned to hardware that start at an earlier position) at the specified rack. (Will return
merged results when passed a resultset referencing multiple racks, which is probably not what
you want, so don't do that.)

This is used for identifying potential conflicts when adjusting layouts.

### with\_user\_role

Constrains the resultset to those where the provided user\_id has (at least) the specified role
in at least one build associated with the specified rack(s).

### user\_has\_role

Checks that the provided user\_id has (at least) the specified role in at least one build
associated with the specified rack(s).

Returns a boolean.

### with\_build\_name

Modifies the resultset to add the `build_name` column.

### with\_full\_rack\_name

Modifies the resultset to add the `full_rack_name` column.

### with\_datacenter\_room\_alias

Modifies the resultset to add the `datacenter_room_alias` column.

### with\_rack\_role\_name

Modifies the resultset to add the `rack_role_name` column.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
