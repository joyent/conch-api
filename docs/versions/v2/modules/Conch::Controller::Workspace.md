# NAME

Conch::Controller::Workspace

# METHODS

## find\_workspace

Chainable action that validates the 'workspace\_id' provided in the path,
and stashes the query to get to it in `workspace_rs`.

The placeholder might actually be a workspace \*name\*, in which case we look up the
corresponding id and stash it for future usage.

## list

Get a list of all workspaces available to the currently authenticated user.

Response uses the WorkspacesAndRoles json schema.

## get

Get the details of the current workspace.

Response uses the WorkspaceAndRole json schema.

## get\_sub\_workspaces

Get all sub workspaces for the current stashed `user_id` and current workspace (as specified
by :workspace\_id in the path)

Response uses the WorkspacesAndRoles json schema.

## create\_sub\_workspace

Create a new subworkspace for the current workspace.

Response uses the WorkspaceAndRole json schema.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
