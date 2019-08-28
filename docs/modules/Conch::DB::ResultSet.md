# NAME

Conch::DB::ResultSet

# DESCRIPTION

Base class for our resultsets, to allow us to add on additional functionality from what is
available in core [DBIx::Class](https://metacpan.org/pod/DBIx::Class).

# METHODS

Methods added are:

- [active](../modules/Conch::DB::Helper::ResultSet::Deactivatable#active)
- [add\_columns](https://metacpan.org/pod/DBIx::Class::Helper::ResultSet::Shortcut#add_columns)
- [as\_epoch](../modules/Conch::DB::Helper::ResultSet::AsEpoch#as_epoch)
- [columns](https://metacpan.org/pod/DBIx::Class::Helper::ResultSet::Shortcut#columns)
- [correlate](https://metacpan.org/pod/DBIx::Class::Helper::ResultSet::CorrelateRelationship#correlate)
- [deactivate](../modules/Conch::DB::Helper::ResultSet::Deactivatable#deactivate)
- [distinct](https://metacpan.org/pod/DBIx::Class::Helper::ResultSet::Shortcut#distinct)
- [except](https://metacpan.org/pod/DBIx::Class::Helper::ResultSet::SetOperations#except)
- [except\_all](https://metacpan.org/pod/DBIx::Class::Helper::ResultSet::SetOperations#except_all)
- [exists](../modules/Conch::DB::Helper::ResultSet::ResultsExist#exists)
- [group\_by](https://metacpan.org/pod/DBIx::Class::Helper::ResultSet::Shortcut#group_by)
- [hri](https://metacpan.org/pod/DBIx::Class::Helper::ResultSet::Shortcut#hri)
- [intersect](https://metacpan.org/pod/DBIx::Class::Helper::ResultSet::SetOperations#intersect)
- [intersect\_all](https://metacpan.org/pod/DBIx::Class::Helper::ResultSet::SetOperations#intersect_all)
- [one\_row](https://metacpan.org/pod/DBIx::Class::Helper::ResultSet::OneRow#one_row)
- [order\_by](https://metacpan.org/pod/DBIx::Class::Helper::ResultSet::Shortcut#order_by)
- [page](https://metacpan.org/pod/DBIx::Class::Helper::ResultSet::Shortcut#page)
- [prefetch](https://metacpan.org/pod/DBIx::Class::Helper::ResultSet::Shortcut#prefetch)
- [remove\_columns](https://metacpan.org/pod/DBIx::Class::Helper::ResultSet::RemoveColumns#remove_columns)
- [rows](https://metacpan.org/pod/DBIx::Class::Helper::ResultSet::Shortcut#rows)
- [union](https://metacpan.org/pod/DBIx::Class::Helper::ResultSet::SetOperations#union)
- [union\_all](https://metacpan.org/pod/DBIx::Class::Helper::ResultSet::SetOperations#union_all)
- [with\_role](../modules/Conch::DB::Helper::ResultSet::WithRole#with_role)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
