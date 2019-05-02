# NAME

Conch::DB::Result::DeviceLocation

# BASE CLASS: [Conch::DB::Result](https://metacpan.org/pod/Conch::DB::Result)

# TABLE: `device_location`

# ACCESSORS

## device\_id

```
data_type: 'text'
is_foreign_key: 1
is_nullable: 0
```

## rack\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## rack\_unit\_start

```
data_type: 'integer'
is_foreign_key: 1
is_nullable: 0
```

## created

```perl
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

## updated

```perl
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

# PRIMARY KEY

- ["device\_id"](#device_id)

# UNIQUE CONSTRAINTS

## `device_location_rack_id_rack_unit_start_key`

- ["rack\_id"](#rack_id)
- ["rack\_unit\_start"](#rack_unit_start)

# RELATIONS

## device

Type: belongs\_to

Related object: [Conch::DB::Result::Device](https://metacpan.org/pod/Conch::DB::Result::Device)

## rack

Type: belongs\_to

Related object: [Conch::DB::Result::Rack](https://metacpan.org/pod/Conch::DB::Result::Rack)

## rack\_layout

Type: belongs\_to

Related object: [Conch::DB::Result::RackLayout](https://metacpan.org/pod/Conch::DB::Result::RackLayout)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
