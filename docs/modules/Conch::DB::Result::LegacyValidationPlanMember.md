# Conch::DB::Result::LegacyValidationPlanMember

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/LegacyValidationPlanMember.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/LegacyValidationPlanMember.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `legacy_validation_plan_member`

## ACCESSORS

### legacy\_validation\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### legacy\_validation\_plan\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## PRIMARY KEY

- ["legacy\_validation\_id"](#legacy_validation_id)
- ["legacy\_validation\_plan\_id"](#legacy_validation_plan_id)

## RELATIONS

### legacy\_validation

Type: belongs\_to

Related object: [Conch::DB::Result::LegacyValidation](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ALegacyValidation)

### legacy\_validation\_plan

Type: belongs\_to

Related object: [Conch::DB::Result::LegacyValidationPlan](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ALegacyValidationPlan)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
