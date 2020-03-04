# NAME

Conch::DB::ResultSet::UserWorkspaceRole

# DESCRIPTION

Interface to queries involving user/workspace permissions.

# METHODS

## with\_permission

Constrains the resultset to those user\_workspace\_role rows that grant (at least) the specified
permission level.

## user\_has\_permission

Returns a boolean indicating whether there exists a user\_workspace\_role row that grant (at
least) the specified permission level.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
