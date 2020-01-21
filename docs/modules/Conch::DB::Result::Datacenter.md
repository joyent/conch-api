# Conch::DB::Result::Datacenter

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `datacenter`

## ACCESSORS

### id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

### vendor

```
data_type: 'text'
is_nullable: 0
```

### vendor\_name

```
data_type: 'text'
is_nullable: 1
```

### region

```
data_type: 'text'
is_nullable: 0
```

### location

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

### `datacenter_vendor_region_location_key`

- ["vendor"](#vendor)
- ["region"](#region)
- ["location"](#location)

## RELATIONS

### datacenter\_rooms

Type: has\_many

Related object: [Conch::DB::Result::DatacenterRoom](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADatacenterRoom)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
