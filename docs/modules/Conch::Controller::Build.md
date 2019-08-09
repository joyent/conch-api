# NAME

Conch::Controller::Build

# METHODS

## list

If the user is a system admin, retrieve a list of all builds in the database; otherwise,
limits the list to those build of which the user is a member.

Response uses the Builds json schema.

## create

Creates a build.

Requires the user to be a system admin.

## find\_build

Chainable action that validates the `build_id` or `build_name` provided in the
path, and stashes the query to get to it in `build_rs`.

If `require_role` is provided, it is used as the minimum required role for the user to
continue; otherwise the user must be a system admin.

## get

Get the details of a single build.
Requires the 'read-only' role on the build.

Response uses the Build json schema.

## update

Modifies a build attribute: one or more of description, started, completed.
Requires the 'admin' role on the build.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
