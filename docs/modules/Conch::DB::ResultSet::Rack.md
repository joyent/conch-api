# NAME

Conch::DB::ResultSet::Rack

# DESCRIPTION

Interface to queries involving racks.

# METHODS

## assigned\_rack\_units

Returns a list of rack\_unit positions that are assigned to current layouts (including positions
assigned to hardware that start at an earlier position) at the specified rack. (Will return
merged results when passed a resultset referencing multiple racks, which is probably not what
you want, so don't do that.)

This is used for identifying potential conflicts when adjusting layouts.

## user\_has\_role

Checks that the provided user\_id has (at least) the specified role in at least one workspace
associated with the specified rack(s) (implicitly including parent workspaces), or at least one
build associated with the rack(s).

Returns a boolean.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
