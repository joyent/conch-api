# Conch::DB::Helper::Row::ToJSON

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/DB/Helper/Row/ToJSON.pm](https://github.com/joyent/conch/blob/master/lib/Conch/DB/Helper/Row/ToJSON.pm)

## DESCRIPTION

A component for [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult) classes to provide serialization functionality via `TO_JSON`.
Sub-classes [DBIx::Class::Helper::Row::ToJSON](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3ARow%3A%3AToJSON) to also serialize 'text' data.

## USAGE

```
__PACKAGE__->load_components('+Conch::DB::Helper::Row::ToJSON');
```

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
