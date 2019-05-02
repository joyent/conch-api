# NAME

Conch::DB::Result::ValidationStateMember

# BASE CLASS: [Conch::DB::Result](https://metacpan.org/pod/Conch::DB::Result)

# TABLE: `validation_state_member`

# ACCESSORS

## validation\_state\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## validation\_result\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

# PRIMARY KEY

- ["validation\_state\_id"](#validation_state_id)
- ["validation\_result\_id"](#validation_result_id)

# RELATIONS

## validation\_result

Type: belongs\_to

Related object: [Conch::DB::Result::ValidationResult](https://metacpan.org/pod/Conch::DB::Result::ValidationResult)

## validation\_state

Type: belongs\_to

Related object: [Conch::DB::Result::ValidationState](https://metacpan.org/pod/Conch::DB::Result::ValidationState)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
