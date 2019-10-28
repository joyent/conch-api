# NAME

Conch::DB::Result::RackLayout

# BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

# TABLE: `rack_layout`

# ACCESSORS

## id

```
data_type: 'uuid'
default_value: gen_random_uuid()
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

## hardware\_product\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## rack\_unit\_start

```
data_type: 'integer'
is_nullable: 0
```

## created

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

## updated

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

# PRIMARY KEY

- ["id"](#id)

# UNIQUE CONSTRAINTS

## `rack_layout_rack_id_rack_unit_start_key`

- ["rack\_id"](#rack_id)
- ["rack\_unit\_start"](#rack_unit_start)

# RELATIONS

## device\_location

Type: might\_have

Related object: [Conch::DB::Result::DeviceLocation](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADeviceLocation)

## hardware\_product

Type: belongs\_to

Related object: [Conch::DB::Result::HardwareProduct](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AHardwareProduct)

## rack

Type: belongs\_to

Related object: [Conch::DB::Result::Rack](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ARack)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
