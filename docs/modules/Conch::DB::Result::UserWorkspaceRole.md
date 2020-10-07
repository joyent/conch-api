# Conch::DB::Result::UserWorkspaceRole

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/UserWorkspaceRole.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/UserWorkspaceRole.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `user_workspace_role`

## ACCESSORS

### user\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### workspace\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### role

```
data_type: 'enum'
default_value: 'ro'
extra: {custom_type_name => "role_enum",list => ["ro","rw","admin"]}
is_nullable: 0
```

## PRIMARY KEY

- ["user\_id"](#user_id)
- ["workspace\_id"](#workspace_id)

## RELATIONS

### user\_account

Type: belongs\_to

Related object: [Conch::DB::Result::UserAccount](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AUserAccount)

### workspace

Type: belongs\_to

Related object: [Conch::DB::Result::Workspace](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AWorkspace)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
