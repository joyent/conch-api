# NAME

Conch - Setup and helpers for Conch Mojo app

# SYNOPSIS

```
Mojolicious::Commands->start_app('Conch');
```

# METHODS

## startup

Used by Mojo in the startup process. Loads the config file and sets up the
helpers, routes and everything else.

# HELPERS

These methods are made available on the `$c` object (the invocant of all controller methods,
and therefore other helpers).

## status

Helper method for setting the response status code and json content.

## startup\_time

Stores a [Conch::Time](../modules/Conch%3A%3ATime) instance representing the time the server started accepting requests.

## host

Retrieves the ["host" in Mojo::URL](https://metacpan.org/pod/Mojo%3A%3AURL#host) portion of the request URL, suitable for constructing base URLs
in user-facing content.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
