# Conch::DB::Result::DeviceNeighbor

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/DeviceNeighbor.pm](https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/DeviceNeighbor.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `device_neighbor`

## ACCESSORS

### mac

```
data_type: 'macaddr'
is_foreign_key: 1
is_nullable: 0
```

### raw\_text

```
data_type: 'text'
is_nullable: 1
```

### peer\_switch

```
data_type: 'text'
is_nullable: 1
```

### peer\_port

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

### updated

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

### peer\_mac

```
data_type: 'macaddr'
is_nullable: 1
```

## PRIMARY KEY

- ["mac"](#mac)

## RELATIONS

### device\_nic

Type: belongs\_to

Related object: [Conch::DB::Result::DeviceNic](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADeviceNic)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
