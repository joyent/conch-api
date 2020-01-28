# Conch::DB::Helper::Row::WithPhase

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/DB/Helper/Row/WithPhase.pm](https://github.com/joyent/conch/blob/master/lib/Conch/DB/Helper/Row/WithPhase.pm)

## DESCRIPTION

A component for [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult) classes for database tables with a `phase` column, to
provide common functionality.

## USAGE

```
__PACKAGE__->load_components('+Conch::DB::Helper::Row::WithPhase');
```

## METHODS

### phase\_cmp

Acts like the `cmp` operator, returning -1, 0 or 1 depending on whether the first phase is
less than, the same as, or greater than the second phase.

If only one phase argument is passed, the phase in the current row is compared to the passed-in
phase.

Accepts undef for one or both phases, which always compare as less than a defined phase.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
