# Conch::DB::Result::LegacyValidationStateMember

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/LegacyValidationStateMember.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result/LegacyValidationStateMember.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `legacy_validation_state_member`

## ACCESSORS

### validation\_state\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### legacy\_validation\_result\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### result\_order

```
data_type: 'integer'
is_nullable: 0
```

## PRIMARY KEY

- ["validation\_state\_id"](#validation_state_id)
- ["legacy\_validation\_result\_id"](#legacy_validation_result_id)

## UNIQUE CONSTRAINTS

### `l_validation_state_member_validation_state_id_result_order_key`

- ["validation\_state\_id"](#validation_state_id)
- ["result\_order"](#result_order)

## RELATIONS

### legacy\_validation\_result

Type: belongs\_to

Related object: [Conch::DB::Result::LegacyValidationResult](../modules/Conch%3A%3ADB%3A%3AResult%3A%3ALegacyValidationResult)

### validation\_state

Type: belongs\_to

Related object: [Conch::DB::Result::ValidationState](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AValidationState)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
