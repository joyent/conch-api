# NAME

Conch::DB::Result::DeviceNic

# BASE CLASS: [Conch::DB::Result](../modules/Conch::DB::Result)

# TABLE: `device_nic`

# ACCESSORS

## mac

```
data_type: 'macaddr'
is_nullable: 0
```

## iface\_name

```
data_type: 'text'
is_nullable: 0
```

## iface\_type

```
data_type: 'text'
is_nullable: 0
```

## iface\_vendor

```
data_type: 'text'
is_nullable: 0
```

## iface\_driver

```
data_type: 'text'
is_nullable: 1
```

## deactivated

```
data_type: 'timestamp with time zone'
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

## state

```
data_type: 'text'
is_nullable: 1
```

## ipaddr

```
data_type: 'inet'
is_nullable: 1
```

## mtu

```
data_type: 'integer'
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

- ["mac"](#mac)

# RELATIONS

## device

Type: belongs\_to

Related object: [Conch::DB::Result::Device](../modules/Conch::DB::Result::Device)

## device\_neighbor

Type: might\_have

Related object: [Conch::DB::Result::DeviceNeighbor](../modules/Conch::DB::Result::DeviceNeighbor)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
