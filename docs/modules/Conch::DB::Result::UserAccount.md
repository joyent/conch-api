# NAME

Conch::DB::Result::UserAccount

# BASE CLASS: [Conch::DB::Result](https://joyent.github.io/conch/modules/Conch::DB::Result)

# TABLE: `user_account`

# ACCESSORS

## id

```
data_type: 'uuid'
default_value: gen_random_uuid()
is_nullable: 0
size: 16
```

## name

```
data_type: 'text'
is_nullable: 0
```

## password\_hash

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

## last\_login

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

## email

```
data_type: 'text'
is_nullable: 0
```

## deactivated

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

## refuse\_session\_auth

```
data_type: 'boolean'
default_value: false
is_nullable: 0
```

## force\_password\_change

```
data_type: 'boolean'
default_value: false
is_nullable: 0
```

## is\_admin

```
data_type: 'boolean'
default_value: false
is_nullable: 0
```

# PRIMARY KEY

- ["id"](#id)

# RELATIONS

## user\_relay\_connections

Type: has\_many

Related object: [Conch::DB::Result::UserRelayConnection](https://joyent.github.io/conch/modules/Conch::DB::Result::UserRelayConnection)

## user\_session\_tokens

Type: has\_many

Related object: [Conch::DB::Result::UserSessionToken](https://joyent.github.io/conch/modules/Conch::DB::Result::UserSessionToken)

## user\_settings

Type: has\_many

Related object: [Conch::DB::Result::UserSetting](https://joyent.github.io/conch/modules/Conch::DB::Result::UserSetting)

## user\_workspace\_roles

Type: has\_many

Related object: [Conch::DB::Result::UserWorkspaceRole](https://joyent.github.io/conch/modules/Conch::DB::Result::UserWorkspaceRole)

# METHODS

## TO\_JSON

Include information about the user's workspaces, if available.

## new

Overrides original to move 'password' to 'password\_hash'.

## update

Overrides original to move 'password' to 'password\_hash'.

## validate\_password

Check whether the given password text has a hash matching the stored password hash.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
