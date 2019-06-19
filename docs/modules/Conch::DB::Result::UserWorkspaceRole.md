# NAME

Conch::DB::Result::UserWorkspaceRole

# BASE CLASS: [Conch::DB::Result](../modules/Conch::DB::Result)

# TABLE: `user_workspace_role`

# ACCESSORS

## user\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## workspace\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## role

```perl
data_type: 'enum'
default_value: 'ro'
extra: {custom_type_name => "user_workspace_role_enum",list => ["ro","rw","admin"]}
is_nullable: 0
```

# PRIMARY KEY

- ["user\_id"](#user_id)
- ["workspace\_id"](#workspace_id)

# UNIQUE CONSTRAINTS

## `user_workspace_role_user_id_workspace_id_role_key`

- ["user\_id"](#user_id)
- ["workspace\_id"](#workspace_id)
- ["role"](#role)

# RELATIONS

## user\_account

Type: belongs\_to

Related object: [Conch::DB::Result::UserAccount](../modules/Conch::DB::Result::UserAccount)

## workspace

Type: belongs\_to

Related object: [Conch::DB::Result::Workspace](../modules/Conch::DB::Result::Workspace)

## role\_cmp

Acts like the `cmp` operator, returning -1, 0 or 1 depending on whether the first role is less
than, the same as, or greater than the second role.

If only one role argument is passed, the role in the current row is compared to the passed-in
role.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
