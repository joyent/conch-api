# NAME

Conch::DB::Result::DatacenterRoom

# BASE CLASS: [Conch::DB::Result](../modules/Conch::DB::Result)

# TABLE: `datacenter_room`

# ACCESSORS

## id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

## datacenter\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## az

```
data_type: 'text'
is_nullable: 0
```

## alias

```
data_type: 'text'
is_nullable: 0
```

## vendor\_name

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

## updated

```perl
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

# PRIMARY KEY

- ["id"](#id)

# UNIQUE CONSTRAINTS

## `datacenter_room_alias_key`

- ["alias"](#alias)

# RELATIONS

## datacenter

Type: belongs\_to

Related object: [Conch::DB::Result::Datacenter](../modules/Conch::DB::Result::Datacenter)

## racks

Type: has\_many

Related object: [Conch::DB::Result::Rack](../modules/Conch::DB::Result::Rack)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
