# NAME

Conch::DB::Helper::Row::WithRole

# DESCRIPTION

A component for [Conch::DB::Result](../modules/Conch::DB::Result) classes for database tables with a `role`
column, to provide common functionality.

# USAGE

```
__PACKAGE__->load_components('+Conch::DB::Helper::Row::WithRole');
```

# METHODS

## role\_cmp

Acts like the `cmp` operator, returning -1, 0 or 1 depending on whether the first role is less
than, the same as, or greater than the second role.

If only one role argument is passed, the role in the current row is compared to the passed-in
role.

Accepts undef for one or both roles, which always compare as less than a defined role.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).