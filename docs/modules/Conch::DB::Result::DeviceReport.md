# NAME

Conch::DB::Result::DeviceReport

# BASE CLASS: [Conch::DB::Result](../modules/Conch::DB::Result)

# TABLE: `device_report`

# ACCESSORS

## id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

## report

```
data_type: 'jsonb'
is_nullable: 1
```

## created

```perl
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

## retain

```
data_type: 'boolean'
is_nullable: 1
```

## device\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

# PRIMARY KEY

- ["id"](#id)

# RELATIONS

## device

Type: belongs\_to

Related object: [Conch::DB::Result::Device](../modules/Conch::DB::Result::Device)

## validation\_states

Type: has\_many

Related object: [Conch::DB::Result::ValidationState](../modules/Conch::DB::Result::ValidationState)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
