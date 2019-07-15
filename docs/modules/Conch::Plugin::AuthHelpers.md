# NAME

Conch::Plugin::AuthHelpers

# DESCRIPTION

Contains all convenience handlers for authentication

# HELPERS

## is\_system\_admin

```
return $c->status(403) if not $c->is_system_admin;
```

Verifies that the currently stashed user has the `is_admin` flag set.

## is\_workspace\_admin

```
return $c->status(403) if not $c->is_workspace_admin;
```

Verifies that the user indicated by the stashed `user_id` has 'admin' permission on the
workspace indicated by the stashed `workspace_id` or one of its ancestors.

## user\_has\_workspace\_auth

Verifies that the user indicated by the stashed `user_id` has (at least) this auth role on the
workspace indicated by the stashed `workspace_id` or one of its ancestors.

Users with the admin flag set will always return true, even if no user\_workspace\_role records
are present.

## generate\_jwt

Generates a session token for the specified user and stores it in the database.
Returns the new row and the JWT.

`expires` is an epoch time.

## generate\_jwt\_from\_token

Given a session token, generate a JWT for it.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
