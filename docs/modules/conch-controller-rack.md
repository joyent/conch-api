# NAME

Conch::Controller::Rack

# METHODS

## find\_rack

Supports rack lookups by uuid.

## create

Stores data as a new rack row, munging 'role' to 'rack\_role\_id'.

## get

Get a single rack

Response uses the Rack json schema.

## get\_all

Get all racks

Response uses the Racks json schema.

## layouts

Gets all the layouts for the specified rack.

Response uses the RackLayouts json schema.

## update

Update an existing rack.

## delete

Delete a rack.

## get\_assignment

Gets all the rack layout assignments (including occupying devices) for the specified rack.

Response uses the RackAssignments json schema.

## set\_assignment

Assigns devices to rack layouts, also optionally updating asset\_tags.

## delete\_assignment

## set\_phase

Updates the phase of this rack, and optionally all devices located in this rack.

Use the `rack_only` query parameter to specify whether to only update the rack's phase, or all
located devices' phases as well.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
