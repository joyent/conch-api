# NAME

Conch::DB::Result::Organization

# BASE CLASS: [Conch::DB::Result](../modules/Conch::DB::Result)

# TABLE: `organization`

# ACCESSORS

## id

```
data_type: 'uuid'
default_value: gen_random_uuid()
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

## created

```perl
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

## deactivated

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

# PRIMARY KEY

- ["id"](#id)

# RELATIONS

## organization\_workspace\_roles

Type: has\_many

Related object: [Conch::DB::Result::OrganizationWorkspaceRole](../modules/Conch::DB::Result::OrganizationWorkspaceRole)

## user\_organization\_roles

Type: has\_many

Related object: [Conch::DB::Result::UserOrganizationRole](../modules/Conch::DB::Result::UserOrganizationRole)

## user\_accounts

Type: many\_to\_many

Composing rels: ["user\_organization\_roles"](#user_organization_roles) -> user\_account

## workspaces

Type: many\_to\_many

Composing rels: ["organization\_workspace\_roles"](#organization_workspace_roles) -> workspace

# METHODS

## TO\_JSON

Include information about the organization's admins and workspaces.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
