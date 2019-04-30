# NAME

Conch::DB::ResultSet::Workspace

# DESCRIPTION

Interface to queries involving workspaces.

Note: in the methods below, "above" and "beneath" are referring to the workspace tree,
where the root ("GLOBAL") workspace is considered to be at the top and child
workspaces hang below as nodes and leaves.

A parent workspace is "above" a given workspace; its children are "beneath".

# METHODS

## workspaces\_beneath

Chainable resultset that finds all sub-workspaces beneath the provided workspace id.

The resultset does \*not\* include the original workspace itself -- see
["and\_workspaces\_beneath"](#and_workspaces_beneath) for that.

## and\_workspaces\_beneath

As [workspaces\_beneath](https://metacpan.org/pod/workspaces_beneath), but also includes the original workspace.

`$workspace_id` can be a single workspace\_id, an arrayref of multiple distinct workspace\_ids,
or a resultset, which must return a single column of distinct workspace\_id(s)).

## workspaces\_above

Chainable resultset that finds all workspaces above the provided workspace id (that is, all
parent workspaces, up to the root).

The resultset does \*not\* include the original workspace itself -- see
["and\_workspaces\_above"](#and_workspaces_above) for that.

## and\_workspaces\_above

As [workspaces\_above](https://metacpan.org/pod/workspaces_above), but also includes the original workspace.

`$workspace_id` can be a single workspace\_id, an arrayref of multiple distinct workspace\_ids,
or a resultset, which must return a single column of distinct workspace\_id(s)).

## with\_role\_via\_data\_for\_user

Query for workspace(s) with an extra field attached to the query which will signal the
workspace serializer to include the "role" and "via" columns, containing information about the
effective permissions the user has for the workspace.

Only one user\_id can be calculated at a time.  If you need to generate workspace-and-role data
for multiple users at once, you can manually do:

```perl
$workspace->user_id_for_role($user_id);
```

before serializing the workspace object.

## role\_via\_for\_user

For a given workspace\_id and user\_id, find the user\_workspace\_role row that is responsible for
providing the user access to the workspace (the user\_workspace\_role with the greatest
permission that is attached to an ancestor workspace).

## \_workspaces\_subquery

Generate values for inserting into a recursive query.
The first value is a string to be added after `WHERE <column>`; the remainder are bind
values to be used in `\[ $query_string, @binds ]`.

`$workspace_id` can be a single workspace\_id, an arrayref of multiple distinct workspace\_ids,
a resultset (which must return a single column of distinct workspace\_id(s)).

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
