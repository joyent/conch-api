# NAME

Test::Conch::Fixtures

# DESCRIPTION

Provides database fixtures for testing.

# USAGE

```perl
my $fixtures = Test::Conch::Fixtures->new(
    definitions => {
        fixture_1 => { ... },
        fixture_2 => { ... },
    },
);
```

See ["fixtures" in Test::Conch](/conch/modules/Test::Conch#fixtures) for main usage.

# METHODS

## generate\_set

Generates new fixture definition(s).  Adds them to the internal definition list, but does not
load them to the database.

Available sets:

\* workspace\_room\_rack\_layout - a new workspace under GLOBAL, with a datacenter\_room,
rack, and a layout suitable for various hardware. Takes a single integer for uniqueness.

## generate\_definitions

Generates fixture definition(s) using generic data, and any necessary dependencies.  Uses a
unique number to generate unique fixture names.  Not-nullable fields are filled in with
sensible defaults, but all may be overridden.

Requires data format:

```perl
fixture_type => { field data.. },
...,
```

`fixture_type` is usually a table name, but might be pluralized or be something special. See
["\_generate\_definition"](#_generate_definition).

## \_generate\_definition

Data used in ["generate\_definitions"](#generate_definitions). Returns a fixture definition as well as a list of other
recognized fixture types that must also be turned into fixtures to satisfy dependencies.

`num` must be a value that is unique to the set of fixtures being generated; many fixtures
will refer to each other using this number as part of their name.

`specification` is usually a hashref but might be a listref depending on the fixture type.

## add\_definition

Add a new fixture definition.

## get\_definition

Used by [DBIx::Class::Fixtures](https://metacpan.org/pod/DBIx::Class::Fixtures).

## all\_fixture\_names

Used by [DBIx::Class::Fixtures](https://metacpan.org/pod/DBIx::Class::Fixtures).

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
