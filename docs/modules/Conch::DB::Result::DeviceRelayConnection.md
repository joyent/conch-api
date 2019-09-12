# NAME

Conch::DB::Result::DeviceRelayConnection

# BASE CLASS: [Conch::DB::Result](../modules/Conch::DB::Result)

# TABLE: `device_relay_connection`

# ACCESSORS

## first\_seen

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

## last\_seen

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

## relay\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## device\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

# PRIMARY KEY

- ["device\_id"](#device_id)
- ["relay\_id"](#relay_id)

# RELATIONS

## device

Type: belongs\_to

Related object: [Conch::DB::Result::Device](../modules/Conch::DB::Result::Device)

## relay

Type: belongs\_to

Related object: [Conch::DB::Result::Relay](../modules/Conch::DB::Result::Relay)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
