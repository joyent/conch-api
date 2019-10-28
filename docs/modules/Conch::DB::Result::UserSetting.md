# NAME

Conch::DB::Result::UserSetting

# BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

# TABLE: `user_setting`

# ACCESSORS

## id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

## user\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## name

```
data_type: 'text'
is_nullable: 0
```

## value

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

## user\_account

Type: belongs\_to

Related object: [Conch::DB::Result::UserAccount](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AUserAccount)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
