# NAME

Conch::DB::Result::HardwareProduct

# BASE CLASS: [Conch::DB::Result](../modules/Conch::DB::Result)

# TABLE: `hardware_product`

# ACCESSORS

## id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

## name

```
data_type: 'text'
is_nullable: 0
```

## alias

```
data_type: 'text'
is_nullable: 0
```

## prefix

```
data_type: 'text'
is_nullable: 1
```

## hardware\_vendor\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
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

## specification

```
data_type: 'jsonb'
is_nullable: 1
```

## sku

```
data_type: 'text'
is_nullable: 1
```

## generation\_name

```
data_type: 'text'
is_nullable: 1
```

## legacy\_product\_name

```
data_type: 'text'
is_nullable: 1
```

# PRIMARY KEY

- ["id"](#id)

# RELATIONS

## devices

Type: has\_many

Related object: [Conch::DB::Result::Device](../modules/Conch::DB::Result::Device)

## hardware\_product\_profile

Type: might\_have

Related object: [Conch::DB::Result::HardwareProductProfile](../modules/Conch::DB::Result::HardwareProductProfile)

## hardware\_vendor

Type: belongs\_to

Related object: [Conch::DB::Result::HardwareVendor](../modules/Conch::DB::Result::HardwareVendor)

## rack\_layouts

Type: has\_many

Related object: [Conch::DB::Result::RackLayout](../modules/Conch::DB::Result::RackLayout)

## validation\_results

Type: has\_many

Related object: [Conch::DB::Result::ValidationResult](../modules/Conch::DB::Result::ValidationResult)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
