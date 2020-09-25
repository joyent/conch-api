# Conch::Controller::Organization

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/Organization.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/Organization.pm)

## METHODS

### get\_all

Retrieve a list of organization details (including each organization's admins).

If the user is a system admin, all active organizations are retrieved; otherwise, limits the
list to those organizations of which the user is a member.

Response uses the Organizations json schema.

### create

Creates an organization.

Requires the user to be a system admin.

### find\_organization

Chainable action that uses the `organization_id_or_name` value provided in the stash (usually
via the request URL) to look up an organization, and stashes the query to get to it in
`organization_rs`.

If `require_role` is provided in the stash, it is used as the minimum required role for the user to
continue; otherwise the user must have the 'admin' role.

### get

Get the details of a single organization, including its members.
Requires the 'admin' role on the organization.

Response uses the Organization json schema.

### update

Modifies an organization attribute: one or more of name, description.
Requires the 'admin' role on the organization.

### delete

Deactivates the organization, preventing its members from exercising any privileges from it.

User must have system admin privileges.

### add\_user

Adds a user to the current organization, or upgrades an existing role entry to access the
organization.
Requires the 'admin' role on the organization.

Optionally takes a query parameter `send_mail` (defaulting to true), to send an email
to the user and to all organization admins.

### remove\_user

Removes the indicated user from the organization.
Requires the 'admin' role on the organization.

Optionally takes a query parameter `send_mail` (defaulting to true), to send an email
to the user and to all organization admins.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
