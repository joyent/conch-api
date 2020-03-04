# NAME

Conch::DB::Deactivatable

# DESCRIPTION

A component for [Conch::DB::ResultSet](/modules/Conch::DB::ResultSet) classes for database tables with a `deactivated`
column, to provide common query functionality.

# USAGE

```
__PACKAGE__->load_components('+Conch::DB::Deactivatable');
```

# METHODS

## active

Chainable resultset to limit results to those that aren't deactivated.

## deactivate

Update all matching rows by setting deactivated = now().

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
