# Conch::DB::Result::DatacenterRoom

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/DatacenterRoom.pm](https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/DatacenterRoom.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `datacenter_room`

## ACCESSORS

### id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

### datacenter\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### az

```
data_type: 'text'
is_nullable: 0
```

### alias

```
data_type: 'text'
is_nullable: 0
```

### vendor\_name

```
data_type: 'text'
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

### `datacenter_room_alias_key`

- ["alias"](#alias)

### `datacenter_room_vendor_name_key`

- ["vendor\_name"](#vendor_name)

## RELATIONS

### datacenter

Type: belongs\_to

Related object: [Conch::DB::Result::Datacenter](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADatacenter)

### racks

Type: has\_many

Related object: [Conch::DB::Result::Rack](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ARack)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
