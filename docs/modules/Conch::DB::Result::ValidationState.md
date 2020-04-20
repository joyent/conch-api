# Conch::DB::Result::ValidationState

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/ValidationState.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/ValidationState.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `validation_state`

## ACCESSORS

### id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

### created

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

### status

```
data_type: 'enum'
extra: {custom_type_name => "validation_status_enum",list => ["error","fail","pass"]}
is_nullable: 0
```

### device\_report\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### device\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### hardware\_product\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## PRIMARY KEY

- ["id"](#id)

## RELATIONS

### device

Type: belongs\_to

Related object: [Conch::DB::Result::Device](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADevice)

### device\_report

Type: belongs\_to

Related object: [Conch::DB::Result::DeviceReport](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADeviceReport)

### hardware\_product

Type: belongs\_to

Related object: [Conch::DB::Result::HardwareProduct](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AHardwareProduct)

### legacy\_validation\_state\_members

Type: has\_many

Related object: [Conch::DB::Result::LegacyValidationStateMember](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ALegacyValidationStateMember)

### legacy\_validation\_results

Type: many\_to\_many

Composing rels: ["legacy\_validation\_state\_members"](#legacy_validation_state_members) -> legacy\_validation\_result

## METHODS

### TO\_JSON

Include all the associated validation results, when available.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
