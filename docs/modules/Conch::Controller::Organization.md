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

Chainable action that validates the `organization_id` or `organization_name` provided in the
path, and stashes the query to get to it in `organization_rs`.

Requires the 'admin' role on the organization (or the user to be a system admin).

## get

Get the details of a single organization.
Requires the 'admin' role on the organization.

Note: the only workspaces and roles listed are those reachable via the organization, even if
the user might have direct access to the workspace at a greater role. For comprehensive
information about what workspaces the user can access, and at what role, please use
`GET /workspace` or `GET /user/me`.

Response uses the Organization json schema.

## delete

Deactivates the organization, preventing its members from exercising any privileges from it.

User must have system admin privileges.

## list\_users

Get a list of members of the current organization.
Requires the 'admin' role on the organization.

Response uses the OrganizationUsers json schema.

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
