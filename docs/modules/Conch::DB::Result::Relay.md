# Conch::DB::Result::Relay

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/Relay.pm](https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/Relay.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `relay`

## ACCESSORS

### serial\_number

```
data_type: 'text'
is_nullable: 0
```

### name

```
data_type: 'text'
is_nullable: 1
```

### version

```
data_type: 'text'
is_nullable: 1
```

### ipaddr

```
data_type: 'inet'
is_nullable: 1
```

### ssh\_port

```
data_type: 'integer'
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

### id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

### last\_seen

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

### user\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## PRIMARY KEY

- ["id"](#id)

## UNIQUE CONSTRAINTS

### `relay_serial_number_key`

- ["serial\_number"](#serial_number)

## RELATIONS

### device\_relay\_connections

Type: has\_many

Related object: [Conch::DB::Result::DeviceRelayConnection](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADeviceRelayConnection)

### user\_account

Type: belongs\_to

Related object: [Conch::DB::Result::UserAccount](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AUserAccount)

### devices

Type: many\_to\_many

Composing rels: ["device\_relay\_connections"](#device_relay_connections) -> device

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
