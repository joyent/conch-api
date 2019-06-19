# NAME

Conch::DB::Result::Device

# BASE CLASS: [Conch::DB::Result](/../modules/Conch::DB::Result)

# TABLE: `device`

# ACCESSORS

## id

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

## state

```
data_type: 'text'
is_nullable: 0
```

## health

```perl
data_type: 'enum'
extra: {custom_type_name => "device_health_enum",list => ["error","fail","unknown","pass"]}
is_nullable: 0
```

## graduated

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

## deactivated

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

## last\_seen

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

## latest\_triton\_reboot

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

## triton\_uuid

```
data_type: 'uuid'
is_nullable: 1
size: 16
```

## asset\_tag

```
data_type: 'text'
is_nullable: 1
```

## triton\_setup

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

## hostname

```
data_type: 'text'
is_nullable: 1
```

## phase

```perl
data_type: 'enum'
default_value: 'integration'
extra: {custom_type_name => "device_phase_enum",list => ["integration","installation","production","diagnostics","decommissioned"]}
is_nullable: 0
```

# PRIMARY KEY

- ["id"](#id)

# UNIQUE CONSTRAINTS

## `device_system_uuid_key`

- ["system\_uuid"](#system_uuid)

# RELATIONS

## device\_disks

Type: has\_many

Related object: [Conch::DB::Result::DeviceDisk](/../modules/Conch::DB::Result::DeviceDisk)

## device\_environment

Type: might\_have

Related object: [Conch::DB::Result::DeviceEnvironment](/../modules/Conch::DB::Result::DeviceEnvironment)

## device\_location

Type: might\_have

Related object: [Conch::DB::Result::DeviceLocation](/../modules/Conch::DB::Result::DeviceLocation)

## device\_nics

Type: has\_many

Related object: [Conch::DB::Result::DeviceNic](/../modules/Conch::DB::Result::DeviceNic)

## device\_relay\_connections

Type: has\_many

Related object: [Conch::DB::Result::DeviceRelayConnection](/../modules/Conch::DB::Result::DeviceRelayConnection)

## device\_reports

Type: has\_many

Related object: [Conch::DB::Result::DeviceReport](/../modules/Conch::DB::Result::DeviceReport)

## device\_settings

Type: has\_many

Related object: [Conch::DB::Result::DeviceSetting](/../modules/Conch::DB::Result::DeviceSetting)

## hardware\_product

Type: belongs\_to

Related object: [Conch::DB::Result::HardwareProduct](/../modules/Conch::DB::Result::HardwareProduct)

## validation\_results

Type: has\_many

Related object: [Conch::DB::Result::ValidationResult](/../modules/Conch::DB::Result::ValidationResult)

## validation\_states

Type: has\_many

Related object: [Conch::DB::Result::ValidationState](/../modules/Conch::DB::Result::ValidationState)

## latest\_report\_data

Returns the JSON-decoded content from the most recent device report.

## device\_settings\_as\_hash

Returns a hash of all (active) device settings.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
