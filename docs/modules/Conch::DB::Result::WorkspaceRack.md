# NAME

Conch::DB::Result::WorkspaceRack

# BASE CLASS: [Conch::DB::Result](https://joyent.github.io/conch/modules/Conch::DB::Result)

# TABLE: `workspace_rack`

# ACCESSORS

## workspace\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## rack\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

# PRIMARY KEY

- ["workspace\_id"](#workspace_id)
- ["rack\_id"](#rack_id)

# RELATIONS

## rack

Type: belongs\_to

Related object: [Conch::DB::Result::Rack](https://joyent.github.io/conch/modules/Conch::DB::Result::Rack)

## workspace

Type: belongs\_to

Related object: [Conch::DB::Result::Workspace](https://joyent.github.io/conch/modules/Conch::DB::Result::Workspace)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
