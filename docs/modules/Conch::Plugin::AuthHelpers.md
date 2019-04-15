# NAME

Conch::Plugin::AuthHelpers

# DESCRIPTION

Contains all convenience handlers for authentication

# HELPERS

## is\_system\_admin

```
return $c->status(403) if not $c->is_system_admin;
```

Verifies that the currently stashed user has the 'is\_admin' flag set

## is\_workspace\_admin

```
return $c->status(403) if not $c->is_workspace_admin;
```

Verifies that the currently stashed user\_id has 'admin' permission on the current workspace (as
specified by :workspace\_id in the path) or one of its ancestors.

## user\_has\_workspace\_auth

Verifies that the currently stashed user\_id has (at least) this auth role on the specified
workspace (as indicated by :workspace\_id in the path).

Users with the admin flag set will always return true, even if no user\_workspace\_role records
are present.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
