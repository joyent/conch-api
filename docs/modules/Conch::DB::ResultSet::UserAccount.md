# NAME

Conch::DB::ResultSet::UserAccount

# DESCRIPTION

Interface to queries against the `user_account` table.

## create

This method is built in to all resultsets.  In [Conch::DB::Result::UserAccount](/conch/modules/Conch::DB::Result::UserAccount) we have
overrides allowing us to receive the `password` key, which we hash into `password_hash`.

```perl
$schema->resultset('user_account') or $c->db_user_accounts
  ->create({
    name => ...,        # required, but usually the same as email :/
    email => ...,       # required
    password => ...,    # required, if password_hash not provided
  });
```

## update

This method is built in to all resultsets.  In [Conch::DB::Result::UserAccount](/conch/modules/Conch::DB::Result::UserAccount) we have
overrides allowing us to receive the `password` key, which we hash into `password_hash`.

```perl
$schema->resultset('user_account') or $c->db_user_accounts
  ->update({
    password => ...,
    ... possibly other things
  });
```

## lookup\_by\_email

Queries for user by (case-insensitive) email address.

If more than one user is found, we return the one created most recently, and a warning will be
logged (via ["single" in DBIx::Class::ResultSet](https://metacpan.org/pod/DBIx::Class::ResultSet#single)).

If you want to search only for \*active\* users, apply the `->active` resultset to the
caller first.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
