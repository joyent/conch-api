# Conch::DB::ResultSet::ValidationState

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/DB/ResultSet/ValidationState.pm](https://github.com/joyent/conch/blob/master/lib/Conch/DB/ResultSet/ValidationState.pm)

## DESCRIPTION

Interface to queries involving validation states.

## METHODS

### latest\_state\_per\_plan

Generates a resultset that returns the single most recent validation\_state entry
per validation plan (using whatever other search criteria are already in the resultset).

The query will be closed off as a subselect (that additional chaining will SELECT FROM),
so it makes a difference whether you add things to the resultset before or after calling this
method.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
