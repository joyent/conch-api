# NAME

Conch::DB::Result::Relay

# BASE CLASS: [Conch::DB::Result](/modules/Conch::DB::Result)

# TABLE: `relay`

# ACCESSORS

## id

```
data_type: 'text'
is_nullable: 0
```

## alias

```
data_type: 'text'
is_nullable: 1
```

## version

```
data_type: 'text'
is_nullable: 1
```

## ipaddr

```
data_type: 'inet'
is_nullable: 1
```

## ssh\_port

```
data_type: 'integer'
is_nullable: 1
```

## deactivated

```
data_type: 'timestamp with time zone'
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

# PRIMARY KEY

- ["id"](#id)

# RELATIONS

## device\_relay\_connections

Type: has\_many

Related object: [Conch::DB::Result::DeviceRelayConnection](/modules/Conch::DB::Result::DeviceRelayConnection)

## user\_relay\_connections

Type: has\_many

Related object: [Conch::DB::Result::UserRelayConnection](/modules/Conch::DB::Result::UserRelayConnection)

## devices

Type: many\_to\_many

Composing rels: ["device\_relay\_connections"](#device_relay_connections) -> device

## user\_accounts

Type: many\_to\_many

Composing rels: ["user\_relay\_connections"](#user_relay_connections) -> user\_account

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
