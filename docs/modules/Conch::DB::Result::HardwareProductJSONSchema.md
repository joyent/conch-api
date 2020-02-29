# Conch::DB::Result::HardwareProductJSONSchema

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/HardwareProductJSONSchema.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/HardwareProductJSONSchema.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `hardware_product_json_schema`

## ACCESSORS

### hardware\_product\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### json\_schema\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### added

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

### added\_user\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## PRIMARY KEY

- ["hardware\_product\_id"](#hardware_product_id)
- ["json\_schema\_id"](#json_schema_id)

## RELATIONS

### added\_user

Type: belongs\_to

Related object: [Conch::DB::Result::UserAccount](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AUserAccount)

### hardware\_product

Type: belongs\_to

Related object: [Conch::DB::Result::HardwareProduct](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AHardwareProduct)

### json\_schema

Type: belongs\_to

Related object: [Conch::DB::Result::JSONSchema](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AJSONSchema)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
