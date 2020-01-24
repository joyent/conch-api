# Conch::DB::Helper::ResultSet::AsEpoch

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/DB/Helper/ResultSet/AsEpoch.pm](https://github.com/joyent/conch/blob/master/lib/Conch/DB/Helper/ResultSet/AsEpoch.pm)

## DESCRIPTION

A component for [Conch::DB::ResultSet](../modules/Conch%3A%3ADB%3A%3AResultSet) classes that provides the `as_epoch` method.

This code is postgres-specific.

## USAGE

```
__PACKAGE__->load_components('+Conch::DB::Helper::ResultSet::AsEpoch');
```

## METHODS

### as\_epoch

Adds to a resultset a selection list for a timestamp column as a unix epoch time.
If the column already existed in the selection list (presumably using the default time format),
it is replaced.

In this example, a `created` column will be included in the result, containing a value in unix
epoch time format (number of seconds since 1970-01-01 00:00:00 UTC).

```
$rs = $rs->as_epoch('created');
```

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
