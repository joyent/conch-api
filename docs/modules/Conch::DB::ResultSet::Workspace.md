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

The resultset does **not** include the original workspace itself -- see
["and\_workspaces\_beneath"](#and_workspaces_beneath) for that.

## and\_workspaces\_beneath

As ["workspaces\_beneath"](#workspaces_beneath), but also includes the original workspace.

`$workspace_id` can be a single workspace\_id, an arrayref of multiple distinct workspace\_ids,
or a resultset, which must return a single column of distinct workspace\_id(s)).

## workspaces\_above

Chainable resultset that finds all workspaces above the provided workspace id (that is, all
parent workspaces, up to the root).

The resultset does **not** include the original workspace itself -- see
["and\_workspaces\_above"](#and_workspaces_above) for that.

## and\_workspaces\_above

As ["workspaces\_above"](#workspaces_above), but also includes the original workspace.

`$workspace_id` can be a single workspace\_id, an arrayref of multiple distinct workspace\_ids,
or a resultset, which must return a single column of distinct workspace\_id(s)).

## add\_role\_column

Query for workspace(s) with an extra field attached to the result, containing information about
the effective role the user has for the workspace.

The indicated role is used directly, with no additional queries done (consequently "role\_via"
will not appear in the serialized data).  This is intended to be used in preference to
["with\_role\_via\_data\_for\_user"](#with_role_via_data_for_user) when the user is a system admin.

## with\_role\_via\_data\_for\_user

Query for workspace(s) with an extra field attached to the query which will signal the
workspace serializer to include the "role", "role\_via\_workspace\_id" and
"role\_via\_organization\_id" columns, containing information about the effective role the user
has for the workspace.

Only one user\_id can be calculated at a time. If you need to generate workspace-and-role data
for multiple users at once, you can manually do:

```perl
$workspace->user_id_for_role($user_id);
```

before serializing the workspace object.

## role\_via\_for\_user

For a given workspace\_id and user\_id, find the user\_workspace\_role or
organization\_workspace\_role row that is responsible for providing the user access to the
workspace (the row with the greatest role that is attached to an ancestor workspace).

How the role is calculated:

- The role on the user\_organization\_role role is **not** used.
- The number of workspaces between `$workspace_id` and the workspace attached to the
user\_workspace\_role or organization\_workspace\_role row is **not** used.
- When both a user\_workspace\_role and organization\_workspace\_role row are found with the same
role, the record directly associated with the workspace (if there is one) is preferred;
otherwise, the user\_workspace\_role row is preferred.

## role\_via\_for\_organization

For a given workspace\_id and organization\_id, find the organization\_workspace\_role row that is
responsible for providing the organization access to the workspace (the
organization\_workspace\_role with the greatest role that is attached to an ancestor
workspace).

## admins

All the 'admin' users for the provided workspace(s).  Pass a true argument to also include all
system admin users in the result.

## with\_user\_role

Constrains the resultset to those where the provided user\_id has (at least) the specified role.
(Does not search recursively; add `->and_workspaces_above($workspace_id)` to your
resultset first, if this is what you want.)

## user\_has\_role

Checks that the provided user\_id has (at least) the specified role in at least one workspace in
the resultset. (Does not search recursively; add `->and_workspaces_above($workspace_id)`
to your resultset first, if this is what you want.)

Both direct `user_workspace_role` entries and joined
`user_organization_role` -> `organization_workspace_role` entries are checked.

Returns a boolean.

## \_workspaces\_subquery

Generate values for inserting into a recursive query.
The first value is a string to be added after `WHERE <column>`; the remainder are bind
values to be used in `\[ $query_string, @binds ]`.

`$workspace_id` can be a single workspace\_id, an arrayref of multiple distinct workspace\_ids,
or a resultset (which must return a single column of distinct workspace\_id(s)).

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
