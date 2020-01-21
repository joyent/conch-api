# Conch::Controller::RackRole

## METHODS

### find\_rack\_role

Chainable action that uses the `rack_role_id_or_name` value provided in the stash (usually via
the request URL) to look up a rack role, and stashes the result in `rack_role`.

### create

Create a new rack role.

### get

Get a single rack role.

Response uses the RackRole json schema.

### get\_all

Get all rack roles.

Response uses the RackRoles json schema.

### update

Modify an existing rack role.

### delete

Delete a rack role.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
