# NAME

Conch::Controller::WorkspaceOrganization

# METHODS

## list\_workspace\_organizations

Get a list of organizations for the current workspace.
Requires the 'admin' role on the workspace.

Response uses the WorkspaceOrganizations json schema.

## add\_workspace\_organization

Adds a organization to the current workspace, or upgrades an existing role entry to access the
workspace.
Requires the 'admin' role on the workspace.

Optionally takes a query parameter `send_mail` (defaulting to true), to send an email
to all organization members and all workspace admins.

## remove\_workspace\_organization

Removes the indicated organization from the workspace, as well as all sub-workspaces.
Requires the 'admin' role on the workspace.

Note this may not have the desired effect if the organization is getting access to the
workspace via a parent workspace. When in doubt, check at `GET
/workspace/:workspace_id/organization`.

Optionally takes a query parameter `send_mail` (defaulting to true), to send an email
to all organization members and to all workspace admins.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
