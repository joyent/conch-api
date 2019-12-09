# NAME

Conch::Controller::Workspace

# METHODS

## find\_workspace

Chainable action that uses the `workspace_id_or__name` provided in the stash (usually via
the request URL) to look up a workspace, and stashes the query to get to it in `workspace_rs`.

If the workspace name is provided, `workspace_id` is looked up and stashed.

`require_role` is used as the minimum required role for the user to continue; otherwise the
user must be a system admin.

## list

Get a list of all workspaces available to the currently authenticated user.

Response uses the WorkspacesAndRoles json schema.

## get

Get the details of the indicated workspace.

Response uses the WorkspaceAndRole json schema.

## get\_sub\_workspaces

Get all sub-workspaces for the indicated workspace.

Response uses the WorkspacesAndRoles json schema.

## create\_sub\_workspace

Create a new subworkspace for the indicated workspace. The user is given the 'admin' role on
the new workspace.

Optionally takes a query parameter `send_mail` (defaulting to true), to send an email
to all parent workspace admins.

Response uses the WorkspaceAndRole json schema.

## \_user\_has\_workspace\_auth

Verifies that the user indicated by the stashed `user_id` has (at least) this role on the
workspace indicated by the provided `workspace_id` or one of its ancestors.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
