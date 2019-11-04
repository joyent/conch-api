# NAME

Conch::DB::Result::Device

# BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

# TABLE: `device`

# ACCESSORS

## serial\_number

```
data_type: 'text'
is_nullable: 0
```

## system\_uuid

```
data_type: 'uuid'
is_nullable: 1
size: 16
```

## hardware\_product\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## health

```
data_type: 'enum'
extra: {custom_type_name => "device_health_enum",list => ["error","fail","unknown","pass"]}
is_nullable: 0
```

## last\_seen

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

## created

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

## updated

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

## uptime\_since

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

## validated

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

## asset\_tag

```
data_type: 'text'
is_nullable: 1
```

## hostname

```
data_type: 'text'
is_nullable: 1
```

## phase

```
data_type: 'enum'
default_value: 'integration'
extra: {custom_type_name => "device_phase_enum",list => ["integration","installation","production","diagnostics","decommissioned"]}
is_nullable: 0
```

## id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

## links

```
data_type: 'text[]'
default_value: '{}'::text[]
is_nullable: 0
```

## build\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 1
size: 16
```

# PRIMARY KEY

- ["id"](#id)

# UNIQUE CONSTRAINTS

## `device_serial_number_key`

- ["serial\_number"](#serial_number)

## `device_system_uuid_key`

- ["system\_uuid"](#system_uuid)

# RELATIONS

## build

Type: belongs\_to

Related object: [Conch::DB::Result::Build](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ABuild)

## device\_disks

Type: has\_many

Related object: [Conch::DB::Result::DeviceDisk](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADeviceDisk)

## device\_location

Type: might\_have

Related object: [Conch::DB::Result::DeviceLocation](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADeviceLocation)

## device\_nics

Type: has\_many

Related object: [Conch::DB::Result::DeviceNic](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADeviceNic)

## device\_relay\_connections

Type: has\_many

Related object: [Conch::DB::Result::DeviceRelayConnection](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADeviceRelayConnection)

## device\_reports

Type: has\_many

Related object: [Conch::DB::Result::DeviceReport](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADeviceReport)

## device\_settings

Type: has\_many

Related object: [Conch::DB::Result::DeviceSetting](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADeviceSetting)

## hardware\_product

Type: belongs\_to

Related object: [Conch::DB::Result::HardwareProduct](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AHardwareProduct)

## validation\_results

Type: has\_many

Related object: [Conch::DB::Result::ValidationResult](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AValidationResult)

## validation\_states

Type: has\_many

Related object: [Conch::DB::Result::ValidationState](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AValidationState)

## relays

Type: many\_to\_many

Composing rels: ["device\_relay\_connections"](#device_relay_connections) -> relay

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
