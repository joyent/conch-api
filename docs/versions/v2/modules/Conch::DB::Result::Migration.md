# NAME

Conch::DB::Result::Migration

# BASE CLASS: [Conch::DB::Result](/modules/Conch::DB::Result)

# TABLE: `migration`

# ACCESSORS

## id

```
data_type: 'integer'
is_auto_increment: 1
is_nullable: 0
sequence: 'migration_id_seq'
```

## created

```perl
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 1
original: {default_value => \"now()"}
```

# PRIMARY KEY

- ["id"](#id)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
