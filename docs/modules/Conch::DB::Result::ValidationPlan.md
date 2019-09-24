# NAME

Conch::DB::Result::ValidationPlan

# BASE CLASS: [Conch::DB::Result](../modules/Conch::DB::Result)

# TABLE: `validation_plan`

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

## description

```
data_type: 'text'
is_nullable: 0
```

## created

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

## deactivated

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

# PRIMARY KEY

- ["id"](#id)

# RELATIONS

## hardware\_products

Type: has\_many

Related object: [Conch::DB::Result::HardwareProduct](../modules/Conch::DB::Result::HardwareProduct)

## validation\_plan\_members

Type: has\_many

Related object: [Conch::DB::Result::ValidationPlanMember](../modules/Conch::DB::Result::ValidationPlanMember)

## validation\_states

Type: has\_many

Related object: [Conch::DB::Result::ValidationState](../modules/Conch::DB::Result::ValidationState)

## validations

Type: many\_to\_many

Composing rels: ["validation\_plan\_members"](#validation_plan_members) -> validation

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
