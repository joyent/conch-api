# NAME

Conch::DB::Helper::Row::ToJSON

# DESCRIPTION

A component for [Conch::DB::Result](../modules/Conch%3A%3ADB%3A%3AResult) classes to provide serialization functionality via `TO_JSON`.
Sub-classes [DBIx::Class::Helper::Row::ToJSON](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelper%3A%3ARow%3A%3AToJSON) to also serialize 'text' data.

# USAGE

```
__PACKAGE__->load_components('+Conch::DB::Helper::Row::ToJSON');
```

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
