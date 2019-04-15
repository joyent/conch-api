# NAME

Conch::Controller::WorkspaceUser

# METHODS

## list

Get a list of users for the current workspace.

Response uses the WorkspaceUsers json schema.

## add\_user

Adds a user to the current workspace (as specified by :workspace\_id in the path), or upgrades an
existing permission to a workspace.

Optionally takes a query parameter 'send\_mail' (defaulting to true), to send an email
to the user.

## remove

Removes the indicated user from the workspace, as well as all sub-workspaces.
Requires 'admin' permissions on the workspace.

Note this may not have the desired effect if the user is getting access to the workspace via
a parent workspace. When in doubt, check at `GET /user/<id or name>`.

Optionally takes a query parameter 'send\_mail' (defaulting to true), to send an email
to the user.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
