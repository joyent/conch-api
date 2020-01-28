# Conch::Plugin::Database

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Plugin/Database.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Plugin/Database.pm)

## DESCRIPTION

Sets up the database and provides convenient accessors to it.

## HELPERS

These methods are made available on the `$c` object (the invocant of all controller methods,
and therefore other helpers).

### schema

Provides read/write access to the database via [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass). Returns a [Conch::DB](../modules/Conch%3A%3ADB) object
that persists for the lifetime of the application.

### rw\_schema

See ["schema"](#schema); can be used interchangeably with it.

### ro\_schema

Provides (guaranteed) read-only access to the database via [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass). Returns a
[Conch::DB](../modules/Conch%3A%3ADB) object that persists for the lifetime of the application.

### db\_&lt;table>s, db\_ro\_&lt;table>s

Provides direct read/write and read-only accessors to resultsets. The table name is used in
the `alias` attribute (see ["alias" in DBIx::Class::ResultSet](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AResultSet#alias)).

### txn\_wrapper

```perl
my $result = $c->txn_wrapper(sub ($c) {
    # many update, delete queries etc...
});

## if the result is false, we errored and rolled back the db...
return $c->status(400) if not $result;
```

Wraps the provided subref in a database transaction, rolling back in case of an exception.
Any provided arguments are passed to the sub, along with the invocant controller.

If the exception is not `'rollback'` (which signals an intentional premature bailout), the
exception will be logged and stored in the stash, of which the first line will be included in
the response if no other response is prepared (see ["status" in Conch](../modules/Conch#status)).

You should **not** render a response in the subref itself, as you will have a difficult time
figuring out afterwards whether `$c->rendered` still needs to be called or not. Instead,
use the subref's return value to signal success.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
