# Conch::DB::ResultSet::UserSessionToken

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/DB/ResultSet/UserSessionToken.pm](https://github.com/joyent/conch/blob/master/lib/Conch/DB/ResultSet/UserSessionToken.pm)

## DESCRIPTION

Interface to queries against the 'user\_session\_token' table.

## METHODS

### expired

Chainable resultset to limit results to those that are expired.

### active

Chainable resultset to limit results to those that are not expired.

### unexpired

Chainable resultset to limit results to those that are not expired.

### login\_only

Chainable resultset to search for login tokens (created via the main `POST /login` flow).

### api\_only

Chainable resultset to search for api tokens (NOT created via the main /login flow).

### expire

Update all matching rows by setting expires = now(). (Returns the number of rows updated.)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
