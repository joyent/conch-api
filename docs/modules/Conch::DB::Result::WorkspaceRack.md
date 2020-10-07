# Conch::DB::Result::WorkspaceRack

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/WorkspaceRack.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/WorkspaceRack.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `workspace_rack`

## ACCESSORS

### workspace\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### rack\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## PRIMARY KEY

- ["workspace\_id"](#workspace_id)
- ["rack\_id"](#rack_id)

## RELATIONS

### rack

Type: belongs\_to

Related object: [Conch::DB::Result::Rack](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ARack)

### workspace

Type: belongs\_to

Related object: [Conch::DB::Result::Workspace](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AWorkspace)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
