# NAME

Conch::DB::Result::Build

# BASE CLASS: [Conch::DB::Result](../modules/Conch::DB::Result)

# TABLE: `build`

# ACCESSORS

## id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

## name

```
data_type: 'text'
is_nullable: 0
```

## description

```
data_type: 'text'
is_nullable: 1
```

## created

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

## started

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

## completed

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

## completed\_user\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 1
size: 16
```

# PRIMARY KEY

- ["id"](#id)

# UNIQUE CONSTRAINTS

## `build_name_key`

- ["name"](#name)

# RELATIONS

## completed\_user

Type: belongs\_to

Related object: [Conch::DB::Result::UserAccount](../modules/Conch::DB::Result::UserAccount)

## devices

Type: has\_many

Related object: [Conch::DB::Result::Device](../modules/Conch::DB::Result::Device)

## organization\_build\_roles

Type: has\_many

Related object: [Conch::DB::Result::OrganizationBuildRole](../modules/Conch::DB::Result::OrganizationBuildRole)

## racks

Type: has\_many

Related object: [Conch::DB::Result::Rack](../modules/Conch::DB::Result::Rack)

## user\_build\_roles

Type: has\_many

Related object: [Conch::DB::Result::UserBuildRole](../modules/Conch::DB::Result::UserBuildRole)

## organizations

Type: many\_to\_many

Composing rels: ["organization\_build\_roles"](#organization_build_roles) -> organization

## user\_accounts

Type: many\_to\_many

Composing rels: ["user\_build\_roles"](#user_build_roles) -> user\_account

# METHODS

## TO\_JSON

Include information about the build's admins and user who marked the build completed.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
