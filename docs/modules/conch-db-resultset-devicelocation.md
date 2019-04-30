# NAME

Conch::DB::ResultSet::DeviceLocation

# DESCRIPTION

Interface to queries involving device locations.

# METHODS

## assign\_device\_location

Atomically assign a device to the provided rack and rack unit start position.

\- checks that the rack layout exists (dying otherwise)
\- removes the current occupant of the location
\- makes the location assignment, moving the device if it had a previous location

## target\_hardware\_product

Returns a resultset that will produce the 'target\_hardware\_product' portion of the
DeviceLocation json schema (one hashref per matching device\_location).

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
