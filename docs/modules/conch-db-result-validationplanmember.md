# NAME

Conch::DB::Result::ValidationPlanMember

# BASE CLASS: [Conch::DB::Result](https://metacpan.org/pod/Conch::DB::Result)

# TABLE: `validation_plan_member`

# ACCESSORS

## validation\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## validation\_plan\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

# PRIMARY KEY

- ["validation\_id"](#validation_id)
- ["validation\_plan\_id"](#validation_plan_id)

# RELATIONS

## validation

Type: belongs\_to

Related object: [Conch::DB::Result::Validation](https://metacpan.org/pod/Conch::DB::Result::Validation)

## validation\_plan

Type: belongs\_to

Related object: [Conch::DB::Result::ValidationPlan](https://metacpan.org/pod/Conch::DB::Result::ValidationPlan)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
