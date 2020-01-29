# Conch::DB::Result::DeviceDisk

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/DeviceDisk.pm](https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/DeviceDisk.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `device_disk`

## ACCESSORS

### id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

### serial\_number

```
data_type: 'text'
is_nullable: 0
```

### slot

```
data_type: 'integer'
is_nullable: 1
```

### size

```
data_type: 'integer'
is_nullable: 1
```

### vendor

```
data_type: 'text'
is_nullable: 1
```

### model

```
data_type: 'text'
is_nullable: 1
```

### firmware

```
data_type: 'text'
is_nullable: 1
```

### transport

```
data_type: 'text'
is_nullable: 1
```

### health

```
data_type: 'text'
is_nullable: 1
```

### drive\_type

```
data_type: 'text'
is_nullable: 1
```

### deactivated

```
data_type: 'timestamp with time zone'
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

### enclosure

```
data_type: 'integer'
is_nullable: 1
```

### hba

```
data_type: 'integer'
is_nullable: 1
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

### `device_disk_serial_number_key`

- ["serial\_number"](#serial_number)

## RELATIONS

### device

Type: belongs\_to

Related object: [Conch::DB::Result::Device](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADevice)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
