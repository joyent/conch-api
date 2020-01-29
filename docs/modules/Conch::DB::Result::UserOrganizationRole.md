# Conch::DB::Result::UserOrganizationRole

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/UserOrganizationRole.pm](https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/UserOrganizationRole.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `user_organization_role`

## ACCESSORS

### user\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### organization\_id

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

- ["user\_id"](#user_id)
- ["organization\_id"](#organization_id)

## RELATIONS

### organization

Type: belongs\_to

Related object: [Conch::DB::Result::Organization](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AOrganization)

### user\_account

Type: belongs\_to

Related object: [Conch::DB::Result::UserAccount](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AUserAccount)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
