# NAME

Conch::DB::Result::ValidationResult

# BASE CLASS: [Conch::DB::Result](../modules/Conch::DB::Result)

# TABLE: `validation_result`

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

## validation\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## message

```
data_type: 'text'
is_nullable: 0
```

## hint

```
data_type: 'text'
is_nullable: 1
```

## status

```
data_type: 'enum'
extra: {custom_type_name => "validation_status_enum",list => ["error","fail","pass"]}
is_nullable: 0
```

## category

```
data_type: 'text'
is_nullable: 0
```

## component

```
data_type: 'text'
is_nullable: 1
```

## result\_order

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

## hardware\_product

Type: belongs\_to

Related object: [Conch::DB::Result::HardwareProduct](../modules/Conch::DB::Result::HardwareProduct)

## validation

Type: belongs\_to

Related object: [Conch::DB::Result::Validation](../modules/Conch::DB::Result::Validation)

## validation\_state\_members

Type: has\_many

Related object: [Conch::DB::Result::ValidationStateMember](../modules/Conch::DB::Result::ValidationStateMember)

## validation\_states

Type: many\_to\_many

Composing rels: ["validation\_state\_members"](#validation_state_members) -> validation\_state

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
