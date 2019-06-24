# NAME

Conch::Controller::Workspace

# METHODS

## find\_workspace

Chainable action that validates the `workspace_id` or `workspace_name` provided in the path,
and stashes the query to get to it in `workspace_rs`.

If `workspace_name` is provided, `workspace_id` is looked up and stashed.

If `require_role` is provided, it is used as the minimum required role for the user to
continue.

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

Create a new subworkspace for the indicated workspace.

Response uses the WorkspaceAndRole json schema.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
