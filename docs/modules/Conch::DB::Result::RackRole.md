# Conch::DB::Result::RackRole

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/RackRole.pm](https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/RackRole.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `rack_role`

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

### rack\_size

```
data_type: 'integer'
is_nullable: 0
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

## PRIMARY KEY

- ["id"](#id)

## UNIQUE CONSTRAINTS

### `rack_role_name_key`

- ["name"](#name)

### `rack_role_name_rack_size_key`

- ["name"](#name)
- ["rack\_size"](#rack_size)

## RELATIONS

### racks

Type: has\_many

Related object: [Conch::DB::Result::Rack](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ARack)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
