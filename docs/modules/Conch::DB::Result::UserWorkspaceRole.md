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
extra: {custom_type_name => "role_enum",list => ["ro","rw","admin"]}
is_nullable: 0
```

# PRIMARY KEY

- ["user\_id"](#user_id)
- ["workspace\_id"](#workspace_id)

# RELATIONS

## user\_account

Type: belongs\_to

Related object: [Conch::DB::Result::UserAccount](../modules/Conch::DB::Result::UserAccount)

## workspace

Type: belongs\_to

Related object: [Conch::DB::Result::Workspace](../modules/Conch::DB::Result::Workspace)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
