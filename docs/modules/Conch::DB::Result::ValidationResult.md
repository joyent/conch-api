# Conch::DB::Result::ValidationResult

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/ValidationResult.pm](https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/ValidationResult.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `validation_result`

## ACCESSORS

### id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

### validation\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### message

```
data_type: 'text'
is_nullable: 0
```

### hint

```
data_type: 'text'
is_nullable: 1
```

### status

```
data_type: 'enum'
extra: {custom_type_name => "validation_status_enum",list => ["error","fail","pass"]}
is_nullable: 0
```

### category

```
data_type: 'text'
is_nullable: 0
```

### component

```
data_type: 'text'
is_nullable: 1
```

### created

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

### device\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## PRIMARY KEY

- ["id"](#id)

## UNIQUE CONSTRAINTS

### `validation_result_all_columns_key`

- ["device\_id"](#device_id)
- ["validation\_id"](#validation_id)
- ["message"](#message)
- ["hint"](#hint)
- ["status"](#status)
- ["category"](#category)
- ["component"](#component)

## RELATIONS

### device

Type: belongs\_to

Related object: [Conch::DB::Result::Device](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADevice)

### validation

Type: belongs\_to

Related object: [Conch::DB::Result::Validation](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AValidation)

### validation\_state\_members

Type: has\_many

Related object: [Conch::DB::Result::ValidationStateMember](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AValidationStateMember)

### validation\_states

Type: many\_to\_many

Composing rels: ["validation\_state\_members"](#validation_state_members) -> validation\_state

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
