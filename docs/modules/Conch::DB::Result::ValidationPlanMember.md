# Conch::DB::Result::ValidationPlanMember

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/ValidationPlanMember.pm](https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/ValidationPlanMember.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `validation_plan_member`

## ACCESSORS

### validation\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### validation\_plan\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## PRIMARY KEY

- ["validation\_id"](#validation_id)
- ["validation\_plan\_id"](#validation_plan_id)

## RELATIONS

### validation

Type: belongs\_to

Related object: [Conch::DB::Result::Validation](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AValidation)

### validation\_plan

Type: belongs\_to

Related object: [Conch::DB::Result::ValidationPlan](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AValidationPlan)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
