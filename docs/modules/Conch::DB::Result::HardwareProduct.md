# Conch::DB::Result::HardwareProduct

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/HardwareProduct.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/HardwareProduct.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `hardware_product`

## ACCESSORS

### id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

### name

```
data_type: 'text'
is_nullable: 0
```

### alias

```
data_type: 'text'
is_nullable: 0
```

### prefix

```
data_type: 'text'
is_nullable: 1
```

### hardware\_vendor\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### deactivated

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

### created

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

### updated

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

### specification

```
data_type: 'jsonb'
default_value: '{}'
is_nullable: 0
```

### sku

```
data_type: 'text'
is_nullable: 0
```

### generation\_name

```
data_type: 'text'
is_nullable: 1
```

### legacy\_product\_name

```
data_type: 'text'
is_nullable: 1
```

### rack\_unit\_size

```
data_type: 'integer'
is_nullable: 0
```

### legacy\_validation\_plan\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### purpose

```
data_type: 'text'
is_nullable: 0
```

### bios\_firmware

```
data_type: 'text'
is_nullable: 0
```

### hba\_firmware

```
data_type: 'text'
is_nullable: 1
```

### cpu\_num

```
data_type: 'integer'
default_value: 0
is_nullable: 0
```

### cpu\_type

```
data_type: 'text'
is_nullable: 1
```

### dimms\_num

```
data_type: 'integer'
default_value: 0
is_nullable: 0
```

### ram\_total

```
data_type: 'integer'
default_value: 0
is_nullable: 0
```

### nics\_num

```
data_type: 'integer'
default_value: 0
is_nullable: 0
```

### sata\_hdd\_num

```
data_type: 'integer'
default_value: 0
is_nullable: 0
```

### sata\_hdd\_size

```
data_type: 'integer'
is_nullable: 1
```

### sata\_hdd\_slots

```
data_type: 'text'
is_nullable: 1
```

### sas\_hdd\_num

```
data_type: 'integer'
default_value: 0
is_nullable: 0
```

### sas\_hdd\_size

```
data_type: 'integer'
is_nullable: 1
```

### sas\_hdd\_slots

```
data_type: 'text'
is_nullable: 1
```

### sata\_ssd\_num

```
data_type: 'integer'
default_value: 0
is_nullable: 0
```

### sata\_ssd\_size

```
data_type: 'integer'
is_nullable: 1
```

### sata\_ssd\_slots

```
data_type: 'text'
is_nullable: 1
```

### psu\_total

```
data_type: 'integer'
default_value: 0
is_nullable: 0
```

### usb\_num

```
data_type: 'integer'
default_value: 0
is_nullable: 0
```

### sas\_ssd\_num

```
data_type: 'integer'
default_value: 0
is_nullable: 0
```

### sas\_ssd\_size

```
data_type: 'integer'
is_nullable: 1
```

### sas\_ssd\_slots

```
data_type: 'text'
is_nullable: 1
```

### nvme\_ssd\_num

```
data_type: 'integer'
default_value: 0
is_nullable: 0
```

### nvme\_ssd\_size

```
data_type: 'integer'
is_nullable: 1
```

### nvme\_ssd\_slots

```
data_type: 'text'
is_nullable: 1
```

### raid\_lun\_num

```
data_type: 'integer'
default_value: 0
is_nullable: 0
```

## PRIMARY KEY

- ["id"](#id)

## RELATIONS

### devices

Type: has\_many

Related object: [Conch::DB::Result::Device](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADevice)

### hardware\_product\_json\_schemas

Type: has\_many

Related object: [Conch::DB::Result::HardwareProductJSONSchema](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AHardwareProductJSONSchema)

### hardware\_vendor

Type: belongs\_to

Related object: [Conch::DB::Result::HardwareVendor](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AHardwareVendor)

### legacy\_validation\_plan

Type: belongs\_to

Related object: [Conch::DB::Result::LegacyValidationPlan](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ALegacyValidationPlan)

### rack\_layouts

Type: has\_many

Related object: [Conch::DB::Result::RackLayout](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ARackLayout)

### validation\_states

Type: has\_many

Related object: [Conch::DB::Result::ValidationState](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AValidationState)

### TO\_JSON

Decode the json-encoded specification field for rendering in responses.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
