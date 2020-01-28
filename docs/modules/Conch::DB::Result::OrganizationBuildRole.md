# Conch::DB::Result::OrganizationBuildRole

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/OrganizationBuildRole.pm](https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/OrganizationBuildRole.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `organization_build_role`

## ACCESSORS

### organization\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### build\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### role

```
data_type: 'enum'
default_value: 'ro'
extra: {custom_type_name => "role_enum",list => ["ro","rw","admin"]}
is_nullable: 0
```

## PRIMARY KEY

- ["organization\_id"](#organization_id)
- ["build\_id"](#build_id)

## RELATIONS

### build

Type: belongs\_to

Related object: [Conch::DB::Result::Build](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ABuild)

### organization

Type: belongs\_to

Related object: [Conch::DB::Result::Organization](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AOrganization)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
