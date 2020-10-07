# Conch::DB::Result::Migration

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/Migration.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/Migration.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `migration`

## ACCESSORS

### id

```
data_type: 'integer'
is_nullable: 0
```

### created

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 1
original: {default_value => \"now()"}
```

## PRIMARY KEY

- ["id"](#id)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
