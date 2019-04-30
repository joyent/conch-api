# NAME

Conch::DB::ResultSet::Rack

# DESCRIPTION

Interface to queries involving racks.

# METHODS

## assigned\_rack\_units

Returns a list of rack\_unit positions that are assigned to current layouts (including positions
assigned to hardware that start at an earlier position) at the specified rack.  (Will return
merged results when passed a resultset referencing multiple racks, so don't do that.)

This is used for identifying potential conflicts when adjusting layouts.

## user\_has\_permission

Checks that the provided user\_id has (at least) the specified permission in at least one
workspace associated with the specified rack(s), including parent workspaces.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
