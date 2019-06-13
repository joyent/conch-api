# NAME

Conch::Plugin::FindHelpers

# DESCRIPTION

Common methods for looking up various data in the database and saving it to the stash, or
generating error responses as appropriate.

These are suitable to be used in `under` calls in various routes, or directly by a controller
method.

# HELPERS

## find\_user

Validates the provided user\_id or email address, and stashes the corresponding user row in
`target_user`.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
