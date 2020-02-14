# Conch::DB::Result::JSONSchema

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/JSONSchema.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/JSONSchema.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `json_schema`

## ACCESSORS

### id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

### type

```
data_type: 'text'
is_nullable: 0
```

### name

```
data_type: 'text'
is_nullable: 0
```

### version

```
data_type: 'integer'
is_nullable: 0
```

### body

```
data_type: 'jsonb'
is_nullable: 0
```

### created

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

### created\_user\_id

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

## PRIMARY KEY

- ["id"](#id)

## UNIQUE CONSTRAINTS

### `json_schema_type_name_version_key`

- ["type"](#type)
- ["name"](#name)
- ["version"](#version)

## RELATIONS

### created\_user

Type: belongs\_to

Related object: [Conch::DB::Result::UserAccount](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AUserAccount)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
