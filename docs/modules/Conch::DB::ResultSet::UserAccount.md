# NAME

Conch::DB::ResultSet::UserAccount

# DESCRIPTION

Interface to queries against the `user_account` table.

## find\_by\_email

Queries for user by (case-insensitive) email address.

If more than one user is found, we return the one created most recently.

If you want to search only for **active** users, apply the `->active` resultset to the
caller first.

## search\_by\_email

Just the resultset for ["find\_by\_email"](#find_by_email).

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
