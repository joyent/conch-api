# Conch::DB::Result::Organization

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/Organization.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/Organization.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `organization`

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

### deactivated

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

## PRIMARY KEY

- ["id"](#id)

## RELATIONS

### organization\_build\_roles

Type: has\_many

Related object: [Conch::DB::Result::OrganizationBuildRole](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AOrganizationBuildRole)

### user\_organization\_roles

Type: has\_many

Related object: [Conch::DB::Result::UserOrganizationRole](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AUserOrganizationRole)

### builds

Type: many\_to\_many

Composing rels: ["organization\_build\_roles"](#organization_build_roles) -> build

### user\_accounts

Type: many\_to\_many

Composing rels: ["user\_organization\_roles"](#user_organization_roles) -> user\_account

## METHODS

### TO\_JSON

Include information about the organization's admins and builds, if available.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
