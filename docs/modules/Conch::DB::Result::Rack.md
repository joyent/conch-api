# Conch::DB::Result::Rack

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/Rack.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/Rack.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `rack`

## ACCESSORS

### id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

### datacenter\_room\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### name

```
data_type: 'text'
is_nullable: 0
```

### rack\_role\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
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

### serial\_number

```
data_type: 'text'
is_nullable: 1
```

### asset\_tag

```
data_type: 'text'
is_nullable: 1
```

### phase

```
data_type: 'enum'
default_value: 'integration'
extra: {custom_type_name => "device_phase_enum",list => ["integration","installation","production","diagnostics","decommissioned"]}
is_nullable: 0
```

### build\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 1
size: 16
```

### links

```
data_type: 'text[]'
default_value: '{}'::text[]
is_nullable: 0
```

## PRIMARY KEY

- ["id"](#id)

## UNIQUE CONSTRAINTS

### `rack_datacenter_room_id_name_key`

- ["datacenter\_room\_id"](#datacenter_room_id)
- ["name"](#name)

## RELATIONS

### build

Type: belongs\_to

Related object: [Conch::DB::Result::Build](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ABuild)

### datacenter\_room

Type: belongs\_to

Related object: [Conch::DB::Result::DatacenterRoom](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADatacenterRoom)

### device\_locations

Type: has\_many

Related object: [Conch::DB::Result::DeviceLocation](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADeviceLocation)

### rack\_layouts

Type: has\_many

Related object: [Conch::DB::Result::RackLayout](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ARackLayout)

### rack\_role

Type: belongs\_to

Related object: [Conch::DB::Result::RackRole](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ARackRole)

### workspace\_racks

Type: has\_many

Related object: [Conch::DB::Result::WorkspaceRack](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AWorkspaceRack)

### workspaces

Type: many\_to\_many

Composing rels: ["workspace\_racks"](#workspace_racks) -> workspace

## METHODS

### TO\_JSON

Include the rack's build, room, role and full rack name (with room location) when available.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
