# Conch::DB::ResultSet::ValidationState

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/ResultSet/ValidationState.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/ResultSet/ValidationState.pm)

## DESCRIPTION

Interface to queries involving validation states.

## METHODS

### with\_legacy\_validation\_results

Generates a resultset that adds the legacy\_validation\_results to the validation\_state(s) in the
resultset (to be rendered as a flat list of results grouped by validation\_state).

### with\_validation\_results

Generates a resultset that adds the validation\_results to the validation\_state(s) in the
resultset (to be rendered as a list json\_schemas, each with a list of errors).

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
