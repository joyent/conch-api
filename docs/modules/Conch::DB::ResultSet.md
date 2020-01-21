# Conch::DB::ResultSet

## DESCRIPTION

Base class for our resultsets, to allow us to add on additional functionality from what is
available in core [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass).

## METHODS

Methods added are:

- [active](../modules/Conch%3A%3ADB%3A%3AHelper%3A%3AResultSet%3A%3ADeactivatable#active)
- [add\_columns](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3AResultSet%3A%3AShortcut#add_columns)
- [as\_epoch](../modules/Conch%3A%3ADB%3A%3AHelper%3A%3AResultSet%3A%3AAsEpoch#as_epoch)
- [columns](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3AResultSet%3A%3AShortcut#columns)
- [correlate](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3AResultSet%3A%3ACorrelateRelationship#correlate)
- [deactivate](../modules/Conch%3A%3ADB%3A%3AHelper%3A%3AResultSet%3A%3ADeactivatable#deactivate)
- [distinct](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3AResultSet%3A%3AShortcut#distinct)
- [except](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3AResultSet%3A%3ASetOperations#except)
- [except\_all](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3AResultSet%3A%3ASetOperations#except_all)
- [exists](../modules/Conch%3A%3ADB%3A%3AHelper%3A%3AResultSet%3A%3AResultsExist#exists)
- [group\_by](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3AResultSet%3A%3AShortcut#group_by)
- [hri](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3AResultSet%3A%3AShortcut#hri)
- [intersect](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3AResultSet%3A%3ASetOperations#intersect)
- [intersect\_all](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3AResultSet%3A%3ASetOperations#intersect_all)
- [one\_row](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3AResultSet%3A%3AOneRow#one_row)
- [order\_by](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3AResultSet%3A%3AShortcut#order_by)
- [page](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3AResultSet%3A%3AShortcut#page)
- [prefetch](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3AResultSet%3A%3AShortcut#prefetch)
- [rows](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3AResultSet%3A%3AShortcut#rows)
- [union](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3AResultSet%3A%3ASetOperations#union)
- [union\_all](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3AResultSet%3A%3ASetOperations#union_all)
- [with\_role](../modules/Conch%3A%3ADB%3A%3AHelper%3A%3AResultSet%3A%3AWithRole#with_role)

## ATTRIBUTES

Resultset attributes added are:

- [remove\_columns](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3AResultSet%3A%3ARemoveColumns#remove_columns)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
