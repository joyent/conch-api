# NAME

Conch::DB::ResultSet::Build

# DESCRIPTION

Interface to queries involving builds.

# METHODS

## admins

All the 'admin' users for the provided build(s).  Pass a true argument to also include all
system admin users in the result.

## with\_user\_role

Constrains the resultset to those builds where the provided user\_id has (at least) the
specified role.

## user\_has\_role

Checks that the provided user\_id has (at least) the specified role in at least one build in the
resultset.

Returns a boolean.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
