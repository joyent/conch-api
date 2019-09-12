# NAME

Conch::DB::Result::ValidationState

# BASE CLASS: [Conch::DB::Result](../modules/Conch::DB::Result)

# TABLE: `validation_state`

# ACCESSORS

## id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

## validation\_plan\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## created

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

## status

```
data_type: 'enum'
extra: {custom_type_name => "validation_status_enum",list => ["error","fail","pass"]}
is_nullable: 0
```

## completed

```
data_type: 'timestamp with time zone'
is_nullable: 0
```

## device\_report\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
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

## device\_report

Type: belongs\_to

Related object: [Conch::DB::Result::DeviceReport](../modules/Conch::DB::Result::DeviceReport)

## validation\_plan

Type: belongs\_to

Related object: [Conch::DB::Result::ValidationPlan](../modules/Conch::DB::Result::ValidationPlan)

## validation\_state\_members

Type: has\_many

Related object: [Conch::DB::Result::ValidationStateMember](../modules/Conch::DB::Result::ValidationStateMember)

## validation\_results

Type: many\_to\_many

Composing rels: ["validation\_state\_members"](#validation_state_members) -> validation\_result

## prefetch\_validation\_results

Add validation\_state\_members, validation\_result rows to the resultset cache. This allows those
rows to be included in serialized data (see ["TO\_JSON"](#to_json)).

The implementation is gross because has-multi accessors always go to the db, so there is no
non-private way of extracting related rows from the result.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
