# NAME

Conch::DB::Result::Rack

# BASE CLASS: [Conch::DB::Result](/modules/Conch::DB::Result)

# TABLE: `rack`

# ACCESSORS

## id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

## datacenter\_room\_id

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

## rack\_role\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
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

## serial\_number

```
data_type: 'text'
is_nullable: 1
```

## asset\_tag

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

# RELATIONS

## datacenter\_room

Type: belongs\_to

Related object: [Conch::DB::Result::DatacenterRoom](/modules/Conch::DB::Result::DatacenterRoom)

## device\_locations

Type: has\_many

Related object: [Conch::DB::Result::DeviceLocation](/modules/Conch::DB::Result::DeviceLocation)

## rack\_layouts

Type: has\_many

Related object: [Conch::DB::Result::RackLayout](/modules/Conch::DB::Result::RackLayout)

## rack\_role

Type: belongs\_to

Related object: [Conch::DB::Result::RackRole](/modules/Conch::DB::Result::RackRole)

## workspace\_racks

Type: has\_many

Related object: [Conch::DB::Result::WorkspaceRack](/modules/Conch::DB::Result::WorkspaceRack)

## workspaces

Type: many\_to\_many

Composing rels: ["workspace\_racks"](#workspace_racks) -> workspace

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
