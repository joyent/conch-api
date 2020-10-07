# Conch::DB::Helper::ResultSet::WithRole

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Helper/ResultSet/WithRole.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Helper/ResultSet/WithRole.pm)

## DESCRIPTION

A component for [Conch::DB::ResultSet](../modules/Conch%3A%3ADB%3A%3AResultSet) classes for database tables with a `role`
column, to provide common query functionality.

## USAGE

```
__PACKAGE__->load_components('+Conch::DB::Helper::ResultSet::WithRole');
```

## METHODS

### with\_role

Constrains the resultset to those rows that grants (at least) the specified role.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
