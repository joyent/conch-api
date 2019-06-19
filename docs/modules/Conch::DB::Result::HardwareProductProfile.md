# NAME

Conch::DB::Result::HardwareProductProfile

# BASE CLASS: [Conch::DB::Result](../modules/Conch::DB::Result)

# TABLE: `hardware_product_profile`

# ACCESSORS

## id

```
data_type: 'uuid'
default_value: gen_random_uuid()
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

## rack\_unit

```
data_type: 'integer'
is_nullable: 0
```

## purpose

```
data_type: 'text'
is_nullable: 0
```

## bios\_firmware

```
data_type: 'text'
is_nullable: 0
```

## hba\_firmware

```
data_type: 'text'
is_nullable: 1
```

## cpu\_num

```
data_type: 'integer'
is_nullable: 0
```

## cpu\_type

```
data_type: 'text'
is_nullable: 0
```

## dimms\_num

```
data_type: 'integer'
is_nullable: 0
```

## ram\_total

```
data_type: 'integer'
is_nullable: 0
```

## nics\_num

```
data_type: 'integer'
is_nullable: 0
```

## sata\_hdd\_num

```
data_type: 'integer'
is_nullable: 1
```

## sata\_hdd\_size

```
data_type: 'integer'
is_nullable: 1
```

## sata\_hdd\_slots

```
data_type: 'text'
is_nullable: 1
```

## sas\_hdd\_num

```
data_type: 'integer'
is_nullable: 1
```

## sas\_hdd\_size

```
data_type: 'integer'
is_nullable: 1
```

## sas\_hdd\_slots

```
data_type: 'text'
is_nullable: 1
```

## sata\_ssd\_num

```
data_type: 'integer'
is_nullable: 1
```

## sata\_ssd\_size

```
data_type: 'integer'
is_nullable: 1
```

## sata\_ssd\_slots

```
data_type: 'text'
is_nullable: 1
```

## psu\_total

```
data_type: 'integer'
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

## usb\_num

```
data_type: 'integer'
is_nullable: 0
```

## sas\_ssd\_num

```
data_type: 'integer'
is_nullable: 1
```

## sas\_ssd\_size

```
data_type: 'integer'
is_nullable: 1
```

## sas\_ssd\_slots

```
data_type: 'text'
is_nullable: 1
```

## nvme\_ssd\_num

```
data_type: 'integer'
is_nullable: 1
```

## nvme\_ssd\_size

```
data_type: 'integer'
is_nullable: 1
```

## nvme\_ssd\_slots

```
data_type: 'text'
is_nullable: 1
```

## raid\_lun\_num

```
data_type: 'integer'
is_nullable: 1
```

# PRIMARY KEY

- ["id"](#id)

# UNIQUE CONSTRAINTS

## `hardware_product_profile_product_id_key`

- ["hardware\_product\_id"](#hardware_product_id)

# RELATIONS

## hardware\_product

Type: belongs\_to

Related object: [Conch::DB::Result::HardwareProduct](../modules/Conch::DB::Result::HardwareProduct)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
