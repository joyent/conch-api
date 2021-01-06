# Conch - Initialization and helpers for Conch Mojo app

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch.pm)

## SYNOPSIS

```
Mojolicious::Commands->start_app('Conch');
```

## METHODS

### startup

Used by Mojo in the startup process. Loads the config file and sets up the
helpers, routes and everything else.

## HELPERS

These methods are made available on the `$c` object (the invocant of all controller methods,
and therefore other helpers).

### status

Helper method for setting the response status code and json content. Calls
`$c->render` as a side-effect.

### res\_location

Simple helper for setting the `Location` header in the response.

### startup\_time

Stores a [Conch::Time](../modules/Conch%3A%3ATime) instance representing the time the server started accepting requests.

### host

Retrieves the ["host" in Mojo::URL](https://metacpan.org/pod/Mojo%3A%3AURL#host) portion of the request URL, suitable for constructing base URLs
in user-facing content.

### banner

Banner text suitable for displaying on startup.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
