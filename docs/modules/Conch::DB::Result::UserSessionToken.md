# Conch::DB::Result::UserSessionToken

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/UserSessionToken.pm](https://github.com/joyent/conch/blob/master/lib/Conch/DB/Result/UserSessionToken.pm)

## BASE CLASS: [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult)

## TABLE: `user_session_token`

## ACCESSORS

### user\_id

```
data_type: 'uuid'
is_foreign_key: 1
is_nullable: 0
size: 16
```

### expires

```
data_type: 'timestamp with time zone'
is_nullable: 0
```

### name

```
data_type: 'text'
is_nullable: 0
```

### created

```
data_type: 'timestamp with time zone'
default_value: current_timestamp
is_nullable: 0
original: {default_value => \"now()"}
```

### last\_used

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

### id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

### last\_ipaddr

```
data_type: 'inet'
is_nullable: 1
```

## PRIMARY KEY

- ["id"](#id)

## UNIQUE CONSTRAINTS

### `user_session_token_user_id_name_key`

- ["user\_id"](#user_id)
- ["name"](#name)

## RELATIONS

### user\_account

Type: belongs\_to

Related object: [Conch::DB::Result::UserAccount](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AUserAccount)

## METHODS

### is\_login

Boolean indicating whether this token was created via the main /login flow.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
