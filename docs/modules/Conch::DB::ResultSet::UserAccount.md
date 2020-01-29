# Conch::DB::ResultSet::UserAccount

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/DB/ResultSet/UserAccount.pm](https://github.com/joyent/conch/blob/master/lib/Conch/DB/ResultSet/UserAccount.pm)

## DESCRIPTION

Interface to queries against the `user_account` table.

## METHODS

### find\_by\_email

Queries for user by (case-insensitive) email address.

If more than one user is found, we return the one created most recently.

If you want to search only for **active** users, apply the `->active` resultset to the
caller first.

### search\_by\_email

Just the resultset for ["find\_by\_email"](#find_by_email).

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
