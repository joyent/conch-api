# NAME

Conch::DB::Result::DeviceEnvironment

# BASE CLASS: [Conch::DB::Result](../modules/Conch::DB::Result)

# TABLE: `device_environment`

# ACCESSORS

## cpu0\_temp

```
data_type: 'integer'
is_nullable: 1
```

## cpu1\_temp

```
data_type: 'integer'
is_nullable: 1
```

## inlet\_temp

```
data_type: 'integer'
is_nullable: 1
```

## exhaust\_temp

```
data_type: 'integer'
is_nullable: 1
```

## psu0\_voltage

```
data_type: 'numeric'
is_nullable: 1
```

## psu1\_voltage

```
data_type: 'numeric'
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

## device\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

# PRIMARY KEY

- ["device\_id"](#device_id)

# RELATIONS

## device

Type: belongs\_to

Related object: [Conch::DB::Result::Device](../modules/Conch::DB::Result::Device)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
