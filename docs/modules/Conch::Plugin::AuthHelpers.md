# Conch::Plugin::AuthHelpers

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Plugin/AuthHelpers.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Plugin/AuthHelpers.pm)

## DESCRIPTION

Contains all convenience handlers for authentication

## HELPERS

These methods are made available on the `$c` object (the invocant of all controller methods,
and therefore other helpers).

### is\_system\_admin

```
return $c->status(403) if not $c->is_system_admin;
```

Verifies that the currently stashed user has the `is_admin` flag set.

### generate\_jwt

Generates a session token for the specified user and stores it in the database.
Returns the new row and the JWT.

`expires` is an epoch time.

### generate\_jwt\_from\_token

Given a session token, generate a JWT for it.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
