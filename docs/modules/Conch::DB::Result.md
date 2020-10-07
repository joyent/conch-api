# Conch::DB::Result

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/Result.pm)

## DESCRIPTION

Base class for our result classes, to allow us to add on additional functionality from what is
available in core [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass).

## METHODS

Methods added are:

- [self\_rs](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3ARow%3A%3ASelfResultSet#self_rs)
- [TO\_JSON](../modules/Conch%3A%3ADB%3A%3AHelper%3A%3ARow%3A%3AToJSON)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
