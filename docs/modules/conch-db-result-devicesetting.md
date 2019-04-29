# NAME

Conch::DB::Result::DeviceSetting

# BASE CLASS: [Conch::DB::Result](https://metacpan.org/pod/Conch::DB::Result)

# TABLE: `device_setting`

# ACCESSORS

## id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

## device\_id

```
data_type: 'text'
is_foreign_key: 1
is_nullable: 0
```

## value

```
data_type: 'text'
is_nullable: 1
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

## deactivated

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

## name

```
data_type: 'text'
is_nullable: 0
```

# PRIMARY KEY

- ["id"](#id)

# RELATIONS

## device

Type: belongs\_to

Related object: [Conch::DB::Result::Device](https://metacpan.org/pod/Conch::DB::Result::Device)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
