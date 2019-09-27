# NAME

Conch::DB::Result::UserAccount

# BASE CLASS: [Conch::DB::Result](../modules/Conch::DB::Result)

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

## password

```
data_type: 'text'
is_nullable: 0
```

## created

```
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

## last\_seen

```
data_type: 'timestamp with time zone'
is_nullable: 1
```

# PRIMARY KEY

- ["id"](#id)

# RELATIONS

## completed\_builds

Type: has\_many

Related object: [Conch::DB::Result::Build](../modules/Conch::DB::Result::Build)

## user\_build\_roles

Type: has\_many

Related object: [Conch::DB::Result::UserBuildRole](../modules/Conch::DB::Result::UserBuildRole)

## user\_organization\_roles

Type: has\_many

Related object: [Conch::DB::Result::UserOrganizationRole](../modules/Conch::DB::Result::UserOrganizationRole)

## user\_relay\_connections

Type: has\_many

Related object: [Conch::DB::Result::UserRelayConnection](../modules/Conch::DB::Result::UserRelayConnection)

## user\_session\_tokens

Type: has\_many

Related object: [Conch::DB::Result::UserSessionToken](../modules/Conch::DB::Result::UserSessionToken)

## user\_settings

Type: has\_many

Related object: [Conch::DB::Result::UserSetting](../modules/Conch::DB::Result::UserSetting)

## user\_workspace\_roles

Type: has\_many

Related object: [Conch::DB::Result::UserWorkspaceRole](../modules/Conch::DB::Result::UserWorkspaceRole)

## builds

Type: many\_to\_many

Composing rels: ["user\_build\_roles"](#user_build_roles) -> build

## organizations

Type: many\_to\_many

Composing rels: ["user\_organization\_roles"](#user_organization_roles) -> organization

## relays

Type: many\_to\_many

Composing rels: ["user\_relay\_connections"](#user_relay_connections) -> relay

## workspaces

Type: many\_to\_many

Composing rels: ["user\_workspace\_roles"](#user_workspace_roles) -> workspace

# METHODS

## check\_password

Checks the provided password against the value in the database, returning true/false.
Because hard cryptography is used, this is \*not\* a fast call!

## TO\_JSON

Include information about the user's workspaces, organizations and builds, if available.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
