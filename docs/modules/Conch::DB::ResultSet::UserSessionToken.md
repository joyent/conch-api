# NAME

Conch::DB::ResultSet::UserSessionToken

# DESCRIPTION

Interface to queries against the 'user\_session\_token' table.

## expired

Chainable resultset to limit results to those that are expired.

## active

Chainable resultset to limit results to those that are not expired.

## unexpired

Chainable resultset to limit results to those that are not expired.

## login\_only

Chainable resultset to search for login tokens (created via the main `POST /login` flow).

## api\_only

Chainable resultset to search for api tokens (NOT created via the main /login flow).

## expire

Update all matching rows by setting expires = now(). (Returns the number of rows updated.)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
