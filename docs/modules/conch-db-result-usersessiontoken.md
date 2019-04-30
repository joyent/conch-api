# NAME

Conch::DB::Result::UserSessionToken

# BASE CLASS: [Conch::DB::Result](https://metacpan.org/pod/Conch::DB::Result)

# TABLE: `user_session_token`

# ACCESSORS

## user\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

## token\_hash

```
data_type: 'bytea'
is_nullable: 0
```

## expires

```
data_type: 'timestamp with time zone'
is_nullable: 0
```

## name

```
data_type: 'text'
is_nullable: 0
```

## created

```perl
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

## last\_used

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

# PRIMARY KEY

- ["user\_id"](#user_id)
- ["token\_hash"](#token_hash)

# UNIQUE CONSTRAINTS

## `user_session_token_user_id_name_key`

- ["user\_id"](#user_id)
- ["name"](#name)

# RELATIONS

## user\_account

Type: belongs\_to

Related object: [Conch::DB::Result::UserAccount](https://metacpan.org/pod/Conch::DB::Result::UserAccount)

# METHODS

## is\_login

Boolean indicating whether this token was created via the main /login flow.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
