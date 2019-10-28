# NAME

Conch::Time - format timestamps as RFC 3337 UTC timestamps

# SYNOPSIS

```perl
use Conch::Time;

my $postgres_timestamp = '2018-01-26 12:24:18.893874-07';
my $time = Conch::Time->new($postgres_timestamp);

$time eq $time; # 1
```

# METHODS

## new

Overloads the constructor to use `->from_string` when a single argument is passed, for example:

```
Conch::Time->new($pg_timestamptz);
```

..and all other constructor modes supported by [Time::Moment](https://metacpan.org/pod/Time%3A%3AMoment).

## now

```perl
my $t = Conch::Time->now;
```

Returns a new object based on the current time, using the UTC timezone.

Times are high resolution and will generate unique timestamps to the
nanosecond.

## from\_epoch

```
Conch::Time->from_epoch(time);

Conch::Time->from_epoch(Time::HiRes::gettimeofday);

Conch::Time->from_epoch(1234567890, 123);
```

See ["from\_epoch" in Time::Moment](https://metacpan.org/pod/Time%3A%3AMoment#from_epoch).

## CONVERSIONS

### rfc3339

Return an RFC3339 compatible string as UTC.
Sub-second precision will use 3, 6 or 9 digits as necessary.

### timestamp

Return an RFC3339 compatible string.

### to\_string

Render the timestamp as a RFC 3339 timestamp string. Used to
overload string coercion.

### TO\_JSON

Renderer for Mojo, as a RFC 3339 timestamp string

### timestamptz

Render a string in PostgreSQL's timestamptz style

### iso8601

Render the timestamp as an ISO8601 extended format, in UTC

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
