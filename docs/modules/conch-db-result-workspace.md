# NAME

Conch::DB::Result::Workspace

# BASE CLASS: [Conch::DB::Result](https://metacpan.org/pod/Conch::DB::Result)

# TABLE: `workspace`

# ACCESSORS

## id

```
data_type: 'uuid'
default_value: uuid_generate_v4()
is_nullable: 0
size: 16
```

## name

```
data_type: 'text'
is_nullable: 0
```

## description

```
data_type: 'text'
is_nullable: 1
```

## parent\_workspace\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 1
size: 16
```

# PRIMARY KEY

- ["id"](#id)

# UNIQUE CONSTRAINTS

## `workspace_name_key`

- ["name"](#name)

# RELATIONS

## parent\_workspace

Type: belongs\_to

Related object: [Conch::DB::Result::Workspace](https://metacpan.org/pod/Conch::DB::Result::Workspace)

## user\_workspace\_roles

Type: has\_many

Related object: [Conch::DB::Result::UserWorkspaceRole](https://metacpan.org/pod/Conch::DB::Result::UserWorkspaceRole)

## workspace\_racks

Type: has\_many

Related object: [Conch::DB::Result::WorkspaceRack](https://metacpan.org/pod/Conch::DB::Result::WorkspaceRack)

## workspaces

Type: has\_many

Related object: [Conch::DB::Result::Workspace](https://metacpan.org/pod/Conch::DB::Result::Workspace)

## racks

Type: many\_to\_many

Composing rels: ["workspace\_racks"](#workspace_racks) -> rack

## TO\_JSON

Include information about the user's permissions, if available.

## user\_id\_for\_role

Accessor for informational column, which is used by the serializer to signal we should fetch
and include inherited role data.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
