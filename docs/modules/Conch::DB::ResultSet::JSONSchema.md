# Conch::DB::ResultSet::JSONSchema

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/ResultSet/JSONSchema.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/ResultSet/JSONSchema.pm)

## DESCRIPTION

Interface to queries involving JSON schemas.

## METHODS

### type

Chainable resultset that restricts the resultset to rows matching the specified `type`.

### name

Chainable resultset that restricts the resultset to rows matching the specified `name`.

### version

Chainable resultset that restricts the resultset to rows matching the specified `version`.

### latest

Chainable resultset that restricts the resultset to the single row with the latest version.
(This won't make any sense when passed a resultset that queries for multiple types and/or
names, so don't do that.)

Does **NOT** take deactivated status into account.

### with\_description

Chainable resultset that adds the `json_schema` `description` to the results.

### with\_created\_user

Chainable resultset that adds columns `created_user.name` and `created_user.email` to the results.

### resource

Chainable resultset that restricts the resultset to the single row that matches
the indicated resource.  (Does **not** fetch the indicated resource content -- you would need a
`->column(...)` for that.)

### with\_latest\_flag

Chainable resultset that adds the `latest` boolean flag to each result, indicating whether
that row is the latest of its type-name series (that is, whether it can be referenced as
`/json_schema/type/name/latest`).

The query will be closed off as a subselect (that additional chaining will SELECT FROM),
so it makes a difference whether you add things to the resultset before or after calling this
method. Note that if the initial resultset filters out some rows from the same type-name series,
the result will not be accurate, as the full series must be visible in order for the partition
query to work!

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
