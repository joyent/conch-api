# DESCRIPTION

Takes care of setting up a [Test::Mojo](https://metacpan.org/pod/Test::Mojo) with the Conch application pre-configured.

Includes JSON validation ability.

```perl
my $t = Test::Conch->new;
$t->get_ok('/')->status_is(200)->json_schema_is('Whatever');
```

# CONSTANTS

# METHODS

## pg

Override with your own [Test::PostgreSQL](https://metacpan.org/pod/Test::PostgreSQL) object if you want to use a custom database, perhaps
with extra settings or loaded with additional data.

This is the attribute to copy if you want multiple Test::Conch objects to be able to talk to
the same database.

## validator

## fixtures

Provides access to the fixtures defined in [Test::Conch::Fixtures](../modules/Test::Conch::Fixtures).
See ["load\_fixture"](#load_fixture).

## new

Constructor. Takes the following arguments:

```
* pg (optional). uses this as the postgres db.
  Otherwise, an empty database is created, using the schema in sql/schema.sql.

* config (optional). adds the provided configuration data.
```

## init\_db

Sets up the database for testing, using the final schema rather than running migrations.
Mirrors functionality in ["initialize\_db" in Conch::DB::Util](../modules/Conch::DB::Util#initialize_db).
No data is added -- you must load all desired fixtures.

Note that the [Test::PostgreSQL](https://metacpan.org/pod/Test::PostgreSQL) object must stay in scope for the duration of your tests.
Returns the [Conch::DB](../modules/Conch::DB) object as well when called in list context.

## ro\_schema

Returns a read-only connection to an existing [Test::PostgreSQL](https://metacpan.org/pod/Test::PostgreSQL) instance.

## status\_is

Wrapper around ["status\_is" in Test::Mojo](https://metacpan.org/pod/Test::Mojo#status_is), adding some additional checks.

```
* successful GET requests should not return 201, 202 (ideally just 200, 204).
* successful DELETE requests should not return 201
* 200 responses should have content.
* 201 and most 30x responses should have a Location header.
* 204 and most 30x responses should not have body content.
```

Also, unexpected responses will dump the response payload.

## location\_is

Stolen from [Test::Mojo](https://metacpan.org/pod/Test::Mojo)'s examples. I don't know why this isn't just part of the interface!

## location\_like

As ["location\_is"](#location_is), but takes a regular expression.

## json\_schema\_is

Adds a method 'json\_schema\_is\` to validate the JSON response of
the most recent request. If given a string, looks up the schema in
\#/definitions in the JSON Schema spec to validate. If given a hash, uses
the hash as the schema to validate.

## json\_cmp\_deeply

Like ["json\_is" in Test::Mojo](https://metacpan.org/pod/Test::Mojo#json_is), but uses ["cmp\_deeply" in Test::Deep](https://metacpan.org/pod/Test::Deep#cmp_deeply) for the comparison instead of
["is\_deep" in Test::More](https://metacpan.org/pod/Test::More#is_deep). This allows for more flexibility in how we test various parts of the
data.

## load\_validation\_plans

Takes an array ref of structured hash refs and creates a validation plan (if it doesn't
exist) and adds specified validation plans for each of the structured hashes.

Each hash has the structure:

```
{
    name        => 'Validation plan name',
    description => 'Validation plan description',
    validations => [
        'Conch::Validation::Foo',
        'Conch::Validation::Bar',
    ]
}
```

If a validation plan by the name already exists, all associations to
validations are dropped before the specified validations are added. This allows
modifying the membership of the validation plans.

Returns the list of validations plan objects.

## load\_validation

Add data for a validator module to the database, if it does not already exist.

## load\_fixture

Populate the database with one or more fixtures.
Returns the objects that were explicitly requested.

## reload\_fixture

Loads the fixture again. Will die if it already exists (you should use ["load\_fixture"](#load_fixture) unless
you are sure it has since been deleted).

## add\_fixture

Add one or more fixture definition(s), and populate the database with it.

## load\_fixture\_set

Generates a set of fixtures by name and optional arguments, then loads them into the database.
See ["generate\_set" in Test::Conch::Fixtures](../modules/Test::Conch::Fixtures#generate_set) for available sets.

## generate\_fixtures

Generate fixture definition(s) using generic data, and any necessary dependencies, and populate
the database with them.

Not-nullable fields are filled in with sensible defaults, but all may be overridden.

e.g.:

```perl
$t->generate_fixtures(
    device_location => { rack_unit_start => 3 },
    rack_layouts => [
        { rack_unit_start => 1 },
        { rack_unit_start => 2 },
        { rack_unit_start => 3 },
    ],
);
```

or, to get all the defaults with no overrides:

```
$t->generate_fixtures('device_location');
```

See ["\_generate\_definition" in Test::Conch::Fixtures](../modules/Test::Conch::Fixtures#generate_definition) for the list of recognized types.

## authenticate

Authenticates a user in the current test instance. Uses default (superuser) credentials if not
provided.  Optionally will bail out of \*all\* tests on failure.

This will set 'user' in the session (`$t->app->session('user')`), so a token is not needed
on subsequent requests.

## txn\_local

Given a subref, execute the code inside a transaction that is rolled back at the end. Useful
for testing with mutated data that should not affect other tests. The subref is called as a
subtest and is invoked with the test object as well as any additional provided arguments.

## email\_cmp\_deeply

Wrapper around ["cmp\_deeply" in Test::Deep](https://metacpan.org/pod/Test::Deep#cmp_deeply) to test the email(s) that were "sent".
`$got` should contain a hashref, or an arrayref of hashrefs, containing the headers and
content of the message(s), allowing you to test any portion of these that you like using
cmp\_deeply constructs.

```perl
$t->email_cmp_deeply([
    {
        To => '"Foo" <foo@conch.us>',
        From => '"Admin' <admin@conch.us>',
        Subject => 'About your new account',
        body => re(qr/^An account has been created for you.*Username:\s+foo.*Email:\s+foo@conch.us\s+Password:/ms),
    },
]);
```

A default 'From' header corresponding to the main test user is added as a default to your
`$expected` message(s) if you don't provide one.

Remember: "Line endings in the body will normalized to CRLF." (see ["create" in Email::Simple](https://metacpan.org/pod/Email::Simple#create))

## email\_not\_sent

Tests that \*no\* email was sent as a result of the last request.

## log\_is

Searches the log lines emitted for the last request for one with the provided message,
which can be either an exact string or anything that [Test::Deep](https://metacpan.org/pod/Test::Deep) recognizes.

If you are expecting a list of message strings (sent at once to the logger), pass a listref
rather than a list.

A log line at any level matches, or you can use a more specific method that matches only
one specific log level:

## log\_debug\_is

## log\_info\_is

## log\_warn\_is

## log\_error\_is

## log\_fatal\_is

## log\_like

Like ["log\_like"](#log_like), but uses a regular expression to express the expected log content.

A log line at any level matches, or you can use a more specific method that matches only
one specific log level:

## log\_debug\_like

## log\_info\_like

## log\_warn\_like

## log\_error\_like

## log\_fatal\_like

## logs\_are

Like ["log\_is"](#log_is), but tests for multiple messages at once.

## reset\_log

Clears the log history. This does not normally need to be explicitly called, since it is
cleared before every request.

## add\_routes

Convenience method to add additional route(s) to the application, without breaking the routes
that are already in a specific order.

`$routes` should be a [Mojolicious::Routes](https://metacpan.org/pod/Mojolicious::Routes) object that holds the route(s) to be added.

## do\_and\_wait\_for\_event

Sets up a [Mojo::Promise](https://metacpan.org/pod/Mojo::Promise) to wait for a specific event name, then executes the first subref
provided. When the event is received \*and\* the task subref has finished, the success subref is
invoked with the argument(s) sent to the event. If the timeout is reached, the failure subref
is called, or if left undefined a test failure is generated.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
