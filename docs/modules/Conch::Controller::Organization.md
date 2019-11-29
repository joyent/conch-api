# NAME

Conch::Controller::Organization

# METHODS

## list

If the user is a system admin, retrieve a list of all active organizations in the database;
otherwise, limits the list to those organizations of which the user is a member.

Note: the only workspaces and roles listed are those reachable via the organization, even if
the user might have direct access to the workspace at a greater role. For comprehensive
information about what workspaces the user can access, and at what role, please use `GET
/workspace` or `GET /user/me`.

Response uses the Organizations json schema.

## create

Creates an organization.

Requires the user to be a system admin.

## find\_organization

Chainable action that uses the `organization_id_or_name` value provided in the stash (usually
via the request URL) to look up a build, and stashes the query to get to it in
`organization_rs`.

If `require_role` is provided, it is used as the minimum required role for the user to
continue; otherwise the user must have the 'admin' role.

## get

Get the details of a single organization.
Requires the 'admin' role on the organization.

Note: the only workspaces and roles listed are those reachable via the organization, even if
the user might have direct access to the workspace at a greater role. For comprehensive
information about what workspaces the user can access, and at what role, please use
`GET /workspace` or `GET /user/me`.

Response uses the Organization json schema.

## update

Modifies an organization attribute: one or more of name, description.
Requires the 'admin' role on the organization.

## delete

Deactivates the organization, preventing its members from exercising any privileges from it.

User must have system admin privileges.

## add\_user

Adds a user to the current organization, or upgrades an existing role entry to access the
organization.
Requires the 'admin' role on the organization.

Optionally takes a query parameter `send_mail` (defaulting to true), to send an email
to the user and to all organization admins.

## remove\_user

Removes the indicated user from the organization.
Requires the 'admin' role on the organization.

Optionally takes a query parameter `send_mail` (defaulting to true), to send an email
to the user and to all organization admins.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).