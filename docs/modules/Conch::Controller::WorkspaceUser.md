# NAME

Conch::Controller::WorkspaceUser

# METHODS

## get\_all

Get a list of users for the indicated workspace (not including system admin users).
Requires the 'admin' role on the workspace.

Response uses the WorkspaceUsers json schema.

## add\_user

Adds a user to the indicated workspace, or upgrades an existing role entry to access the
workspace.
Requires the 'admin' role on the workspace.

Optionally takes a query parameter `send_mail` (defaulting to true), to send an email
to the user and to all workspace admins.

## remove

Removes the indicated user from the workspace, as well as all sub-workspaces.
Requires the 'admin' role for the workspace.

Note this may not have the desired effect if the user is getting access to the workspace via
a parent workspace. When in doubt, check at `GET /user/<id or name>`.

Optionally takes a query parameter `send_mail` (defaulting to true), to send an email
to the user and to all workspace admins.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
