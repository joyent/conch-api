# Conch::DB::ResultSet::Build

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/ResultSet/Build.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/ResultSet/Build.pm)

## DESCRIPTION

Interface to queries involving builds.

## METHODS

### admins

All the 'admin' users for the provided build(s). Pass a true argument to also include all
system admin users in the result.

### with\_user\_role

Constrains the resultset to those builds where the provided user\_id has (at least) the
specified role.

### user\_has\_role

Checks that the provided user\_id has (at least) the specified role in at least one build in the
resultset.

Returns a boolean.

### with\_device\_health\_counts

Modifies the resultset to add on a column named `device_health` containing an array of arrays
of correlated counts of device.health values for each build.

### with\_device\_phase\_counts

Modifies the resultset to add on a column named `device_phases` containing an array of arrays
of correlated counts of device.phase values for each build.

### with\_rack\_phase\_counts

Modifies the resultset to add on a column named `rack_phases` containing an array of arrays
of correlated counts of rack.phase values for each build.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
