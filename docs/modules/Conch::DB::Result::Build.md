# Conch::DB::Result::Build

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/Build.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/Build.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `build`

## ACCESSORS

### id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

### name

```
data_type: 'text'
is_nullable: 0
```

### description

```
data_type: 'text'
is_nullable: 1
```

### created

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

### started

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

### completed

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

### completed\_user\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 1
size: 16
```

## PRIMARY KEY

- ["id"](#id)

## UNIQUE CONSTRAINTS

### `build_name_key`

- ["name"](#name)

## RELATIONS

### completed\_user

Type: belongs\_to

Related object: [Conch::DB::Result::UserAccount](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AUserAccount)

### devices

Type: has\_many

Related object: [Conch::DB::Result::Device](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ADevice)

### organization\_build\_roles

Type: has\_many

Related object: [Conch::DB::Result::OrganizationBuildRole](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AOrganizationBuildRole)

### racks

Type: has\_many

Related object: [Conch::DB::Result::Rack](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ARack)

### user\_build\_roles

Type: has\_many

Related object: [Conch::DB::Result::UserBuildRole](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AUserBuildRole)

### organizations

Type: many\_to\_many

Composing rels: ["organization\_build\_roles"](#organization_build_roles) -> organization

### user\_accounts

Type: many\_to\_many

Composing rels: ["user\_build\_roles"](#user_build_roles) -> user\_account

## METHODS

### TO\_JSON

Include information about the build's admins and user who marked the build completed.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
