# NAME

Conch::Role::MojoLog - Provide logging to a Mojo controllers

# DESCRIPTION

This role provides a log method for a Mojo controller that adds additional
context to the logs

# SYNOPSIS

```perl
use Role::Tiny::With;
with 'Conch::Role::MojoLog';

sub wat ($c) {
    $c->log->debug('message');
}
```

# METHODS

## log

The logger itself. The usual levels are available, like debug, warn, etc.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
