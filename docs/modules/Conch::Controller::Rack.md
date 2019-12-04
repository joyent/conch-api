# NAME

Conch::Controller::Rack

# METHODS

## find\_rack

Chainable action that uses the `rack_id_or_name` value provided in the stash (usually via the
request URL) to look up a rack (constraining to the datacenter\_room if `datacenter_room_rs` is
also provided) and stashes the query to get to it in `rack_rs`.

When datacenter\_room information is **not** provided, `rack_id_or_name` must be either a uuid
or a "long" rack name (["vendor\_name" in Conch::DB::Result::DatacenterRoom](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADatacenterRoom#vendor_name)) plus
["name" in Conch::DB::Result::Rack](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ARack#name)); otherwise, it can also be a short rack name
["name" in Conch::DB::Result::Rack](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ARack#name)).

If `require_role` is provided, it is used as the minimum required role for the user to
continue; otherwise the user must be a system admin.

## create

Stores data as a new rack row.

## get

Get a single rack

Response uses the Rack json schema.

## get\_layouts

Gets all the layouts for the specified rack.

Response uses the RackLayouts json schema.

## overwrite\_layouts

Given the layout definitions for an entire rack, removes all existing layouts that are not in
the new definition, as well as removing any device\_location assignments in those layouts.

## update

Update an existing rack.

## delete

Delete a rack.

## get\_assignment

Gets all the rack layout assignments (including occupying devices) for the specified rack.

Response uses the RackAssignments json schema.

## set\_assignment

Assigns devices to rack layouts, also optionally updating serial\_numbers and asset\_tags (and
creating the device if needed). Existing devices in referenced slots will be unassigned as needed.

Note: the assignment is still performed even if there is no physical room in the rack
for the new hardware (its rack\_unit\_size overlaps into a subsequent layout), or if the device's
hardware doesn't match what the layout specifies.

## delete\_assignment

## set\_phase

Updates the phase of this rack, and optionally all devices located in this rack.

Use the `rack_only` query parameter to specify whether to only update the rack's phase, or all
located devices' phases as well.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
