# NAME

Conch::DB::Result::UserRelayConnection

# BASE CLASS: [Conch::DB::Result](https://metacpan.org/pod/Conch::DB::Result)

# TABLE: `user_relay_connection`

# ACCESSORS

## user\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## relay\_id

```
data_type: 'text'
is_foreign_key: 1
is_nullable: 0
```

## first\_seen

```perl
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

## last\_seen

```perl
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

# PRIMARY KEY

- ["user\_id"](#user_id)
- ["relay\_id"](#relay_id)

# RELATIONS

## relay

Type: belongs\_to

Related object: [Conch::DB::Result::Relay](https://metacpan.org/pod/Conch::DB::Result::Relay)

## user\_account

Type: belongs\_to

Related object: [Conch::DB::Result::UserAccount](https://metacpan.org/pod/Conch::DB::Result::UserAccount)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
