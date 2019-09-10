# NAME

Conch::DB::Helper::Row::ToJSON

# DESCRIPTION

A component for [Conch::DB::Result](../modules/Conch::DB::Result) classes to provide serialization functionality via `TO_JSON`.
Sub-classes [DBIx::Class::Helper::Row::ToJSON](https://metacpan.org/pod/DBIx::Class::Helper::Row::ToJSON) to also serialize 'text' data.

# USAGE

```
__PACKAGE__->load_components('+Conch::DB::Helper::Row::ToJSON');
```

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
