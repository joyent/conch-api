# NAME

Conch::DB::Helper::ResultSet::WithRole

# DESCRIPTION

A component for [Conch::DB::ResultSet](../modules/Conch::DB::ResultSet) classes for database tables with a `role`
column, to provide common query functionality.

# USAGE

```
__PACKAGE__->load_components('+Conch::DB::Helper::ResultSet::WithRole');
```

# METHODS

## with\_role

Constrains the resultset to those rows that grants (at least) the specified role.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
