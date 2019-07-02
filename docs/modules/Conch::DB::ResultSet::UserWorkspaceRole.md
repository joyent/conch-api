# NAME

Conch::DB::ResultSet::UserWorkspaceRole

# DESCRIPTION

Interface to queries involving user/workspace roles.

# METHODS

## with\_role

Constrains the resultset to those user\_workspace\_role rows that grants (at least) the specified
role.

## user\_has\_role

Returns a boolean indicating whether there exists a user\_workspace\_role row that grants (at
least) the specified role.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
