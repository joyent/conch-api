# NAME

Conch::Controller::WorkspaceRack

# METHODS

## list

Get a list of racks for the indicated workspace.

Response uses the WorkspaceRackSummary json schema.

## find\_rack

Chainable action that takes the `rack_id` provided in the path and looks it up in the
database, stashing a resultset to access it as `rack_rs`.

## add

Add a rack to a workspace, unless it is the GLOBAL workspace, provided the rack
is assigned to the parent workspace of this one.

## remove

Remove a rack from a workspace (and all descendants).

Requires 'admin' permissions on the workspace.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
